;; Standards Compliance Contract
;; Records ethical requirements and standards

(define-data-var admin principal tx-sender)

;; Map to store standards
(define-map standards
  { standard-id: (string-utf8 32) }
  {
    name: (string-utf8 100),
    description: (string-utf8 256),
    category: (string-utf8 50),
    created-at: uint
  }
)

;; Map to track supplier compliance with standards
(define-map supplier-compliance
  {
    supplier-id: (string-utf8 32),
    standard-id: (string-utf8 32)
  }
  {
    compliant: bool,
    updated-at: uint
  }
)

;; Add a new standard
(define-public (add-standard (standard-id (string-utf8 32)) (name (string-utf8 100)) (description (string-utf8 256)) (category (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? standards { standard-id: standard-id })) (err u100))
    (ok (map-set standards
      { standard-id: standard-id }
      {
        name: name,
        description: description,
        category: category,
        created-at: block-height
      }
    ))
  )
)

;; Update supplier compliance status
(define-public (update-compliance (supplier-id (string-utf8 32)) (standard-id (string-utf8 32)) (compliant bool))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? standards { standard-id: standard-id })) (err u404))
    (ok (map-set supplier-compliance
      {
        supplier-id: supplier-id,
        standard-id: standard-id
      }
      {
        compliant: compliant,
        updated-at: block-height
      }
    ))
  )
)

;; Check if a supplier complies with a standard
(define-read-only (check-compliance (supplier-id (string-utf8 32)) (standard-id (string-utf8 32)))
  (match (map-get? supplier-compliance { supplier-id: supplier-id, standard-id: standard-id })
    compliance (ok (get compliant compliance))
    (err u404)
  )
)

;; Get standard details
(define-read-only (get-standard-details (standard-id (string-utf8 32)))
  (map-get? standards { standard-id: standard-id })
)

;; Change admin (only current admin can do this)
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
