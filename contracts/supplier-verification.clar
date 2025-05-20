;; Supplier Verification Contract
;; Validates suppliers in the supply chain

(define-data-var admin principal tx-sender)

;; Map to store verified suppliers
(define-map suppliers
  { supplier-id: (string-utf8 32) }
  {
    name: (string-utf8 100),
    address: (string-utf8 100),
    verified: bool,
    verification-date: uint
  }
)

;; Add a new supplier to the system
(define-public (register-supplier (supplier-id (string-utf8 32)) (name (string-utf8 100)) (address (string-utf8 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? suppliers { supplier-id: supplier-id })) (err u100))
    (ok (map-set suppliers
      { supplier-id: supplier-id }
      {
        name: name,
        address: address,
        verified: false,
        verification-date: u0
      }
    ))
  )
)

;; Verify a supplier
(define-public (verify-supplier (supplier-id (string-utf8 32)))
  (let ((supplier (unwrap! (map-get? suppliers { supplier-id: supplier-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set suppliers
      { supplier-id: supplier-id }
      (merge supplier {
        verified: true,
        verification-date: block-height
      })
    ))
  )
)

;; Check if a supplier is verified
(define-read-only (is-supplier-verified (supplier-id (string-utf8 32)))
  (match (map-get? suppliers { supplier-id: supplier-id })
    supplier (ok (get verified supplier))
    (err u404)
  )
)

;; Get supplier details
(define-read-only (get-supplier-details (supplier-id (string-utf8 32)))
  (map-get? suppliers { supplier-id: supplier-id })
)

;; Change admin (only current admin can do this)
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
