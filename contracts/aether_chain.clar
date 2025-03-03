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
(define-constant err-invalid-status (err u110))

;; Product Status Types
(define-data-var status-types (list 5 (string-ascii 12))
  (list "ACTIVE" "RETIRED" "LOST" "STOLEN" "SERVICING"))

;; Event Types
(define-data-var event-types (list 10 (string-ascii 24))
  (list 
    "PRODUCT_REGISTERED"
    "OWNERSHIP_TRANSFER"
    "STATUS_CHANGE"
    "MAINTENANCE"
    "WARRANTY_UPDATE"
    "CERTIFICATION"
    "DEALER_CHANGE"
    "TECHNICIAN_CHANGE"
    "BATCH_OPERATION"
    "SYSTEM_UPDATE"
  ))

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
        early-notification: uint,
        status: (string-ascii 12)
    }
)

;; Enhanced Event System
(define-map events 
    {event-id: uint}
    {
        event-type: (string-ascii 24),
        product-id: (string-ascii 48),
        data: (string-ascii 256),
        timestamp: uint,
        principal: principal,
        metadata: (optional (string-ascii 256))
    }
)

;; [Previous maps remain unchanged...]

;; Enhanced Event Logging
(define-private (log-event-enhanced 
    (event-type (string-ascii 24)) 
    (product-id (string-ascii 48)) 
    (data (string-ascii 256))
    (metadata (optional (string-ascii 256))))
    (let
        ((event-id (+ (var-get last-event-id) u1)))
        (var-set last-event-id event-id)
        (map-set events
            {event-id: event-id}
            {
                event-type: event-type,
                product-id: product-id,
                data: data,
                timestamp: block-height,
                principal: tx-sender,
                metadata: metadata
            }
        )
    )
)

;; Status Management
(define-public (update-product-status 
    (product-id (string-ascii 48)) 
    (new-status (string-ascii 12)))
    (let
        ((product (unwrap! (map-get? products {product-id: product-id}) err-product-not-found)))
        (asserts! (is-valid-status new-status) err-invalid-status)
        (asserts! (or 
            (is-eq tx-sender (get manufacturer product))
            (is-eq tx-sender (get current-owner product))) 
            err-not-authorized)
        (ok (begin
            (map-set products
                {product-id: product-id}
                (merge product {status: new-status}))
            (log-event-enhanced 
                "STATUS_CHANGE"
                product-id
                new-status
                (some (concat "Previous status: " (get status product))))
        ))
    )
)

;; Status Validation
(define-private (is-valid-status (status (string-ascii 12)))
    (default-to false (some (index-of (var-get status-types) status)))
)

;; [Previous functions remain unchanged...]
