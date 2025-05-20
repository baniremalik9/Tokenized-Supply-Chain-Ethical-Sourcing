;; Certification Contract
;; Records authenticated ethical claims

(define-data-var admin principal tx-sender)

;; Map to store certifications
(define-map certifications
  { certification-id: (string-utf8 32) }
  {
    supplier-id: (string-utf8 32),
    standard-id: (string-utf8 32),
    issuer: principal,
    issue-date: uint,
    expiry-date: uint,
    status: bool,
    metadata: (string-utf8 256)
  }
)

;; Issue a new certification
(define-public (issue-certification (certification-id (string-utf8 32)) (supplier-id (string-utf8 32)) (standard-id (string-utf8 32)) (expiry-date uint) (metadata (string-utf8 256)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? certifications { certification-id: certification-id })) (err u100))
    (asserts! (> expiry-date block-height) (err u101))
    (ok (map-set certifications
      { certification-id: certification-id }
      {
        supplier-id: supplier-id,
        standard-id: standard-id,
        issuer: tx-sender,
        issue-date: block-height,
        expiry-date: expiry-date,
        status: true,
        metadata: metadata
      }
    ))
  )
)

;; Revoke a certification
(define-public (revoke-certification (certification-id (string-utf8 32)))
  (let ((cert (unwrap! (map-get? certifications { certification-id: certification-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set certifications
      { certification-id: certification-id }
      (merge cert { status: false })
    ))
  )
)

;; Check if a certification is valid
(define-read-only (is-certification-valid (certification-id (string-utf8 32)))
  (match (map-get? certifications { certification-id: certification-id })
    cert (and (get status cert) (> (get expiry-date cert) block-height))
    false
  )
)

;; Get certification details
(define-read-only (get-certification-details (certification-id (string-utf8 32)))
  (map-get? certifications { certification-id: certification-id })
)

;; Get all certifications for a supplier
(define-read-only (verify-supplier-certification (supplier-id (string-utf8 32)) (certification-id (string-utf8 32)))
  (match (map-get? certifications { certification-id: certification-id })
    cert (if (is-eq (get supplier-id cert) supplier-id)
            (ok (and (get status cert) (> (get expiry-date cert) block-height)))
            (err u404))
    (err u404)
  )
)

;; Change admin (only current admin can do this)
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
