;; Usage Analytics Contract
;; Analyzes knowledge usage patterns

(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_INVALID_PERIOD (err u501))

;; Data structures
(define-map daily-stats uint {
  total-views: uint,
  unique-users: uint,
  content-created: uint,
  searches-performed: uint
})

(define-map user-activity principal {
  total-views: uint,
  content-created: uint,
  last-active: uint,
  favorite-categories: (list 5 (string-ascii 50))
})

(define-map content-analytics uint {
  daily-views: uint,
  weekly-views: uint,
  monthly-views: uint,
  bounce-rate: uint,
  avg-time-spent: uint
})

(define-data-var current-day uint u0)

;; Public functions
(define-public (record-view (content-id uint) (time-spent uint))
  (let ((user tx-sender)
        (today (get-current-day)))
    (update-daily-stats today)
    (update-user-activity user)
    (update-content-analytics content-id time-spent)
    (ok true)
  )
)

(define-public (record-content-creation (creator principal) (category (string-ascii 50)))
  (let ((today (get-current-day)))
    (update-creator-stats creator category)
    (increment-daily-content-creation today)
    (ok true)
  )
)

(define-public (record-search-activity (user principal))
  (let ((today (get-current-day)))
    (increment-daily-searches today)
    (update-user-search-activity user)
    (ok true)
  )
)

;; Private functions
(define-private (get-current-day)
  (/ block-height u144) ;; Assuming 144 blocks per day
)

(define-private (update-daily-stats (day uint))
  (let ((current-stats (default-to { total-views: u0, unique-users: u0, content-created: u0, searches-performed: u0 }
                                  (map-get? daily-stats day))))
    (map-set daily-stats day (merge current-stats { total-views: (+ (get total-views current-stats) u1) }))
  )
)

(define-private (update-user-activity (user principal))
  (let ((current-activity (default-to { total-views: u0, content-created: u0, last-active: u0, favorite-categories: (list) }
                                     (map-get? user-activity user))))
    (map-set user-activity user (merge current-activity {
      total-views: (+ (get total-views current-activity) u1),
      last-active: block-height
    }))
  )
)

(define-private (update-content-analytics (content-id uint) (time-spent uint))
  (let ((current-analytics (default-to { daily-views: u0, weekly-views: u0, monthly-views: u0, bounce-rate: u0, avg-time-spent: u0 }
                                      (map-get? content-analytics content-id))))
    (map-set content-analytics content-id (merge current-analytics {
      daily-views: (+ (get daily-views current-analytics) u1),
      avg-time-spent: (calculate-avg-time-spent (get avg-time-spent current-analytics) time-spent)
    }))
  )
)

(define-private (update-creator-stats (creator principal) (category (string-ascii 50)))
  (let ((current-activity (default-to { total-views: u0, content-created: u0, last-active: u0, favorite-categories: (list) }
                                     (map-get? user-activity creator))))
    (map-set user-activity creator (merge current-activity {
      content-created: (+ (get content-created current-activity) u1)
    }))
  )
)

(define-private (increment-daily-content-creation (day uint))
  (let ((current-stats (default-to { total-views: u0, unique-users: u0, content-created: u0, searches-performed: u0 }
                                  (map-get? daily-stats day))))
    (map-set daily-stats day (merge current-stats { content-created: (+ (get content-created current-stats) u1) }))
  )
)

(define-private (increment-daily-searches (day uint))
  (let ((current-stats (default-to { total-views: u0, unique-users: u0, content-created: u0, searches-performed: u0 }
                                  (map-get? daily-stats day))))
    (map-set daily-stats day (merge current-stats { searches-performed: (+ (get searches-performed current-stats) u1) }))
  )
)

(define-private (update-user-search-activity (user principal))
  (let ((current-activity (default-to { total-views: u0, content-created: u0, last-active: u0, favorite-categories: (list) }
                                     (map-get? user-activity user))))
    (map-set user-activity user (merge current-activity { last-active: block-height }))
  )
)

(define-private (calculate-avg-time-spent (current-avg uint) (new-time uint))
  (/ (+ current-avg new-time) u2)
)

;; Read-only functions
(define-read-only (get-daily-stats (day uint))
  (map-get? daily-stats day)
)

(define-read-only (get-user-activity (user principal))
  (map-get? user-activity user)
)

(define-read-only (get-content-analytics (content-id uint))
  (map-get? content-analytics content-id)
)

(define-read-only (get-current-day-stats)
  (map-get? daily-stats (get-current-day))
)
