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
(define-constant err-invalid-batch (err u108))
(define-constant err-invalid-interval (err u109))

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
        warranty-expiry: uint,
        service-window: uint,
        early-notification: uint
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

;; Event definitions
(define-data-var last-event-id uint u0)

(define-map events 
    {event-id: uint}
    {
        event-type: (string-ascii 24),
        product-id: (string-ascii 48),
        data: (string-ascii 256),
        timestamp: uint
    }
)

;; Helper functions
(define-private (validate-service-interval (interval uint))
    (and (>= interval u1440) (<= interval u52560))  ;; Between 10 days and 1 year
)

(define-private (log-event (event-type (string-ascii 24)) (product-id (string-ascii 48)) (data (string-ascii 256)))
    (let
        ((event-id (+ (var-get last-event-id) u1)))
        (var-set last-event-id event-id)
        (map-set events
            {event-id: event-id}
            {
                event-type: event-type,
                product-id: product-id,
                data: data,
                timestamp: block-height
            }
        )
    )
)

;; Enhanced Product Registration
(define-public (register-product-batch
    (product-ids (list 20 (string-ascii 48)))
    (description (string-ascii 256))
    (warranty-period uint)
    (service-interval uint))
    (begin
        (asserts! (is-manufacturer tx-sender) err-not-manufacturer)
        (asserts! (validate-service-interval service-interval) err-invalid-interval)
        (asserts! (> (len product-ids) u0) err-invalid-batch)
        (ok (map register-single-product product-ids))
    )
)

(define-private (register-single-product (product-id (string-ascii 48)))
    (let
        ((exists (map-get? products {product-id: product-id})))
        (asserts! (is-none exists) err-product-exists)
        (map-set products
            {product-id: product-id}
            {
                manufacturer: tx-sender,
                current-owner: tx-sender,
                creation-time: block-height,
                description: description,
                is-authentic: true,
                last-service: block-height,
                next-service: (+ block-height service-interval),
                warranty-expiry: (+ block-height warranty-period),
                service-window: u1440,  ;; Default 10-day window
                early-notification: u720 ;; Default 5-day early notification
            }
        )
        (log-event "PRODUCT_REGISTERED" product-id description)
        true
    )
)

;; [Previous functions remain unchanged...]

;; Enhanced Service Management
(define-public (update-service-schedule
    (product-id (string-ascii 48))
    (new-interval uint)
    (service-window uint)
    (early-notification uint))
    (let
        ((product (unwrap! (map-get? products {product-id: product-id}) err-product-not-found)))
        (asserts! (is-manufacturer tx-sender) err-not-manufacturer)
        (asserts! (validate-service-interval new-interval) err-invalid-interval)
        (ok (map-set products
            {product-id: product-id}
            (merge product {
                next-service: (+ block-height new-interval),
                service-window: service-window,
                early-notification: early-notification
            })))
    )
)

;; [Remaining functions unchanged...]
