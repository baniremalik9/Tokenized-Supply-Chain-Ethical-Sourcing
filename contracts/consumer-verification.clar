;; Consumer Verification Contract
;; Enables confirmation of ethical practices

(define-data-var admin principal tx-sender)

;; Map to store products and their supply chain
(define-map products
  { product-id: (string-utf8 32) }
  {
    name: (string-utf8 100),
    manufacturer: (string-utf8 32),
    suppliers: (list 10 (string-utf8 32)),
    created-at: uint
  }
)

;; Register a new product
(define-public (register-product (product-id (string-utf8 32)) (name (string-utf8 100)) (manufacturer (string-utf8 32)) (suppliers (list 10 (string-utf8 32))))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? products { product-id: product-id })) (err u100))
    (ok (map-set products
      { product-id: product-id }
      {
        name: name,
        manufacturer: manufacturer,
        suppliers: suppliers,
        created-at: block-height
      }
    ))
  )
)

;; Update product suppliers
(define-public (update-product-suppliers (product-id (string-utf8 32)) (suppliers (list 10 (string-utf8 32))))
  (let ((product (unwrap! (map-get? products { product-id: product-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set products
      { product-id: product-id }
      (merge product { suppliers: suppliers })
    ))
  )
)

;; Get product details
(define-read-only (get-product-details (product-id (string-utf8 32)))
  (map-get? products { product-id: product-id })
)

;; Verify if a supplier is part of a product's supply chain
(define-read-only (is-supplier-in-product-chain (product-id (string-utf8 32)) (supplier-id (string-utf8 32)))
  (match (map-get? products { product-id: product-id })
    product (ok (is-some (index-of (get suppliers product) supplier-id)))
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
