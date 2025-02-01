;; AetherChain - Luxury Goods Supply Chain Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-manufacturer (err u101))
(define-constant err-not-authorized (err u102))
(define-constant err-product-exists (err u103))
(define-constant err-product-not-found (err u104))
(define-constant err-not-owner (err u105))
(define-constant err-not-certified (err u106))
(define-constant err-invalid-date (err u107))

;; Data Variables
(define-map manufacturers principal bool)
(define-map authorized-dealers principal bool)
(define-map certified-technicians principal bool)

(define-map products 
    {product-id: (string-ascii 48)}
    {
        manufacturer: principal,
        current-owner: principal,
        creation-time: uint,
        description: (string-ascii 256),
        is-authentic: bool,
        last-service: uint,
        next-service: uint,
        warranty-expiry: uint
    }
)

(define-map product-history
    {product-id: (string-ascii 48)}
    {transfers: (list 20 {from: principal, to: principal, time: uint})}
)

(define-map maintenance-records
    {product-id: (string-ascii 48)}
    {services: (list 20 {technician: principal, date: uint, notes: (string-ascii 256)})}
)

;; Manufacturer Management
(define-public (register-manufacturer (manufacturer-address principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set manufacturers manufacturer-address true))
    )
)

;; Dealer Management
(define-public (register-dealer (dealer-address principal))
    (begin
        (asserts! (is-manufacturer tx-sender) err-not-manufacturer)
        (ok (map-set authorized-dealers dealer-address true))
    )
)

;; Technician Management
(define-public (register-technician (tech-address principal))
    (begin
        (asserts! (is-manufacturer tx-sender) err-not-manufacturer)
        (ok (map-set certified-technicians tech-address true))
    )
)

;; Product Management
(define-public (register-product 
    (product-id (string-ascii 48))
    (description (string-ascii 256))
    (warranty-period uint)
    (service-interval uint))
    (let
        ((exists (map-get? products {product-id: product-id})))
        (asserts! (is-manufacturer tx-sender) err-not-manufacturer)
        (asserts! (is-none exists) err-product-exists)
        (ok (map-set products
            {product-id: product-id}
            {
                manufacturer: tx-sender,
                current-owner: tx-sender,
                creation-time: block-height,
                description: description,
                is-authentic: true,
                last-service: block-height,
                next-service: (+ block-height service-interval),
                warranty-expiry: (+ block-height warranty-period)
            }))
    )
)

(define-public (service-product
    (product-id (string-ascii 48))
    (notes (string-ascii 256)))
    (let
        ((product (unwrap! (map-get? products {product-id: product-id}) err-product-not-found))
         (records (default-to {services: (list)} (map-get? maintenance-records {product-id: product-id}))))
        (asserts! (is-certified-tech tx-sender) err-not-certified)
        (try! (map-set products
            {product-id: product-id}
            (merge product {
                last-service: block-height,
                next-service: (+ block-height u17280)
            })))
        (ok (map-set maintenance-records
            {product-id: product-id}
            {services: (unwrap-panic (as-max-len? 
                (append (get services records)
                    {technician: tx-sender, date: block-height, notes: notes})
                u20))}))
    )
)

(define-public (transfer-product
    (product-id (string-ascii 48))
    (new-owner principal))
    (let
        ((product (unwrap! (map-get? products {product-id: product-id}) err-product-not-found))
         (history (default-to {transfers: (list)} (map-get? product-history {product-id: product-id}))))
        (asserts! (is-eq (get current-owner product) tx-sender) err-not-owner)
        (asserts! (or (is-authorized new-owner) (is-manufacturer new-owner)) err-not-authorized)
        (try! (map-set products
            {product-id: product-id}
            (merge product {current-owner: new-owner})))
        (ok (map-set product-history
            {product-id: product-id}
            {transfers: (unwrap-panic (as-max-len? 
                (append (get transfers history) 
                    {from: tx-sender, to: new-owner, time: block-height})
                u20))}))
    )
)

;; Read-only functions
(define-read-only (is-manufacturer (address principal))
    (default-to false (map-get? manufacturers address))
)

(define-read-only (is-authorized (address principal))
    (default-to false (map-get? authorized-dealers address))
)

(define-read-only (is-certified-tech (address principal))
    (default-to false (map-get? certified-technicians address))
)

(define-read-only (get-product-info (product-id (string-ascii 48)))
    (map-get? products {product-id: product-id})
)

(define-read-only (get-product-history (product-id (string-ascii 48)))
    (map-get? product-history {product-id: product-id})
)

(define-read-only (get-maintenance-history (product-id (string-ascii 48)))
    (map-get? maintenance-records {product-id: product-id})
)

(define-read-only (verify-authenticity (product-id (string-ascii 48)))
    (match (map-get? products {product-id: product-id})
        product (ok (get is-authentic product))
        err-product-not-found
    )
)

(define-read-only (check-warranty-status (product-id (string-ascii 48)))
    (match (map-get? products {product-id: product-id})
        product (ok (> (get warranty-expiry product) block-height))
        err-product-not-found
    )
)

(define-read-only (service-due (product-id (string-ascii 48)))
    (match (map-get? products {product-id: product-id})
        product (ok (>= block-height (get next-service product)))
        err-product-not-found
    )
)
