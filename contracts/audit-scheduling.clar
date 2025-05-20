;; Audit Scheduling Contract
;; Manages compliance verification audits

(define-data-var admin principal tx-sender)

;; Define audit status constants
(define-constant STATUS-SCHEDULED u1)
(define-constant STATUS-COMPLETED u2)
(define-constant STATUS-FAILED u3)
(define-constant STATUS-CANCELLED u4)

;; Map to store audits
(define-map audits
  { audit-id: (string-utf8 32) }
  {
    supplier-id: (string-utf8 32),
    auditor: principal,
    scheduled-date: uint,
    status: uint,
    results: (optional (string-utf8 256)),
    updated-at: uint
  }
)

;; Schedule a new audit
(define-public (schedule-audit (audit-id (string-utf8 32)) (supplier-id (string-utf8 32)) (auditor principal) (scheduled-date uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? audits { audit-id: audit-id })) (err u100))
    (asserts! (> scheduled-date block-height) (err u101))
    (ok (map-set audits
      { audit-id: audit-id }
      {
        supplier-id: supplier-id,
        auditor: auditor,
        scheduled-date: scheduled-date,
        status: STATUS-SCHEDULED,
        results: none,
        updated-at: block-height
      }
    ))
  )
)

;; Update audit status (completed or failed)
(define-public (update-audit-status (audit-id (string-utf8 32)) (status uint) (results (optional (string-utf8 256))))
  (let ((audit (unwrap! (map-get? audits { audit-id: audit-id }) (err u404))))
    (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get auditor audit))) (err u403))
    (asserts! (or (is-eq status STATUS-COMPLETED) (is-eq status STATUS-FAILED) (is-eq status STATUS-CANCELLED)) (err u102))
    (ok (map-set audits
      { audit-id: audit-id }
      (merge audit {
        status: status,
        results: results,
        updated-at: block-height
      })
    ))
  )
)

;; Get audit details
(define-read-only (get-audit-details (audit-id (string-utf8 32)))
  (map-get? audits { audit-id: audit-id })
)

;; Get supplier's audit history
(define-read-only (get-supplier-audit-status (supplier-id (string-utf8 32)) (audit-id (string-utf8 32)))
  (match (map-get? audits { audit-id: audit-id })
    audit (if (is-eq (get supplier-id audit) supplier-id)
            (ok (get status audit))
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
