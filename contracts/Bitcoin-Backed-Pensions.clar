(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_ALREADY_REGISTERED (err u2))
(define-constant ERR_NOT_REGISTERED (err u3))
(define-constant ERR_NOT_RETIREMENT_AGE (err u4))
(define-constant ERR_INSUFFICIENT_BALANCE (err u5))
(define-constant ERR_INVALID_AMOUNT (err u6))
(define-constant ERR_INVALID_AGE (err u7))
(define-constant ERR_EMERGENCY_DISABLED (err u8))
(define-constant ERR_WITHDRAWAL_DISABLED (err u9))

(define-data-var minimum-contribution uint u1000000)
(define-data-var retirement-age uint u65)
(define-data-var contract-enabled bool true)
(define-data-var emergency-enabled bool false)
(define-data-var total-participants uint u0)
(define-data-var total-contributions uint u0)

(define-map participants principal 
  {
    balance: uint,
    age: uint,
    registration-block: uint,
    last-contribution-block: uint,
    total-contributed: uint,
    can-withdraw: bool
  })

(define-map contribution-history
  { participant: principal, contribution-id: uint }
  {
    amount: uint,
    block-height: uint,
    timestamp: uint
  })

(define-map participant-contribution-count principal uint)

(define-public (register-participant (participant-age uint))
  (let ((sender tx-sender))
    (asserts! (var-get contract-enabled) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= participant-age u18) (<= participant-age u100)) ERR_INVALID_AGE)
    (asserts! (is-none (map-get? participants sender)) ERR_ALREADY_REGISTERED)
    
    (map-set participants sender
      {
        balance: u0,
        age: participant-age,
        registration-block: stacks-block-height,
        last-contribution-block: u0,
        total-contributed: u0,
        can-withdraw: false
      })
    
    (map-set participant-contribution-count sender u0)
    (var-set total-participants (+ (var-get total-participants) u1))
    (ok true)))

(define-public (contribute (amount uint))
  (let (
    (sender tx-sender)
    (current-participant (unwrap! (map-get? participants sender) ERR_NOT_REGISTERED))
    (contribution-count (default-to u0 (map-get? participant-contribution-count sender)))
  )
    (asserts! (var-get contract-enabled) ERR_NOT_AUTHORIZED)
    (asserts! (>= amount (var-get minimum-contribution)) ERR_INVALID_AMOUNT)
    
    (try! (stx-transfer? amount sender (as-contract tx-sender)))
    
    (map-set participants sender
      (merge current-participant
        {
          balance: (+ (get balance current-participant) amount),
          last-contribution-block: stacks-block-height,
          total-contributed: (+ (get total-contributed current-participant) amount)
        }))
    
    (map-set contribution-history
      { participant: sender, contribution-id: contribution-count }
      {
        amount: amount,
        block-height: stacks-block-height,
        timestamp: (unwrap-panic (get-stacks-block-info? time stacks-block-height))
      })
    
    (map-set participant-contribution-count sender (+ contribution-count u1))
    (var-set total-contributions (+ (var-get total-contributions) amount))
    (ok true)))

(define-public (withdraw (amount uint))
  (let (
    (sender tx-sender)
    (participant (unwrap! (map-get? participants sender) ERR_NOT_REGISTERED))
    (current-age (calculate-current-age participant))
  )
    (asserts! (var-get contract-enabled) ERR_NOT_AUTHORIZED)
    (asserts! (>= current-age (var-get retirement-age)) ERR_NOT_RETIREMENT_AGE)
    (asserts! (>= (get balance participant) amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (try! (as-contract (stx-transfer? amount tx-sender sender)))
    
    (map-set participants sender
      (merge participant
        { balance: (- (get balance participant) amount) }))
    
    (ok true)))

(define-public (withdraw-full)
  (let (
    (sender tx-sender)
    (participant (unwrap! (map-get? participants sender) ERR_NOT_REGISTERED))
    (balance (get balance participant))
  )
    (asserts! (> balance u0) ERR_INSUFFICIENT_BALANCE)
    (try! (withdraw balance))
    (ok balance)))

(define-public (emergency-withdraw (amount uint))
  (let (
    (sender tx-sender)
    (participant (unwrap! (map-get? participants sender) ERR_NOT_REGISTERED))
    (penalty-amount (calculate-penalty amount))
    (withdrawal-amount (- amount penalty-amount))
  )
    (asserts! (var-get emergency-enabled) ERR_EMERGENCY_DISABLED)
    (asserts! (>= (get balance participant) amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (try! (as-contract (stx-transfer? withdrawal-amount tx-sender sender)))
    
    (map-set participants sender
      (merge participant
        { balance: (- (get balance participant) amount) }))
    
    (ok withdrawal-amount)))

(define-public (update-retirement-eligibility (participant principal))
  (let ((participant-data (unwrap! (map-get? participants participant) ERR_NOT_REGISTERED)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    (map-set participants participant
      (merge participant-data
        { can-withdraw: (>= (calculate-current-age participant-data) (var-get retirement-age)) }))
    
    (ok true)))

(define-public (set-minimum-contribution (new-minimum uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set minimum-contribution new-minimum)
    (ok true)))

(define-public (set-retirement-age (new-age uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= new-age u50) (<= new-age u80)) ERR_INVALID_AGE)
    (var-set retirement-age new-age)
    (ok true)))

(define-public (toggle-contract (enabled bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set contract-enabled enabled)
    (ok true)))

(define-public (toggle-emergency-withdrawals (enabled bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set emergency-enabled enabled)
    (ok true)))

(define-read-only (get-participant (participant principal))
  (map-get? participants participant))

(define-read-only (get-participant-balance (participant principal))
  (match (map-get? participants participant)
    participant-data (some (get balance participant-data))
    none))

(define-read-only (get-total-contributions)
  (var-get total-contributions))

(define-read-only (get-total-participants)
  (var-get total-participants))

(define-read-only (get-minimum-contribution)
  (var-get minimum-contribution))

(define-read-only (get-retirement-age)
  (var-get retirement-age))

(define-read-only (is-contract-enabled)
  (var-get contract-enabled))

(define-read-only (is-emergency-enabled)
  (var-get emergency-enabled))

(define-read-only (get-contribution-history (participant principal) (contribution-id uint))
  (map-get? contribution-history { participant: participant, contribution-id: contribution-id }))

(define-read-only (get-participant-contribution-count (participant principal))
  (default-to u0 (map-get? participant-contribution-count participant)))

(define-read-only (is-eligible-for-retirement (participant principal))
  (match (map-get? participants participant)
    participant-data (>= (calculate-current-age participant-data) (var-get retirement-age))
    false))

(define-read-only (get-years-until-retirement (participant principal))
  (match (map-get? participants participant)
    participant-data 
      (let ((current-age (calculate-current-age participant-data)))
        (if (>= current-age (var-get retirement-age))
          u0
          (- (var-get retirement-age) current-age)))
    u0))

(define-read-only (calculate-penalty (amount uint))
  (/ (* amount u20) u100))

(define-read-only (estimate-retirement-value (participant principal))
  (match (map-get? participants participant)
    participant-data
      (let (
        (years-contributing (calculate-years-since-registration participant-data))
        (annual-growth-rate u5)
        (compound-factor (+ u100 (* annual-growth-rate years-contributing)))
      )
        (some (/ (* (get balance participant-data) compound-factor) u100)))
    none))

(define-private (calculate-current-age (participant-data (tuple (balance uint) (age uint) (registration-block uint) (last-contribution-block uint) (total-contributed uint) (can-withdraw bool))))
  (let (
    (blocks-since-registration (- stacks-block-height (get registration-block participant-data)))
    (years-passed (/ blocks-since-registration u52560))
  )
    (+ (get age participant-data) years-passed)))

(define-private (calculate-years-since-registration (participant-data (tuple (balance uint) (age uint) (registration-block uint) (last-contribution-block uint) (total-contributed uint) (can-withdraw bool))))
  (let ((blocks-since-registration (- stacks-block-height (get registration-block participant-data))))
    (/ blocks-since-registration u52560)))

(define-read-only (get-contract-stats)
  {
    total-participants: (var-get total-participants),
    total-contributions: (var-get total-contributions),
    minimum-contribution: (var-get minimum-contribution),
    retirement-age: (var-get retirement-age),
    contract-enabled: (var-get contract-enabled),
    emergency-enabled: (var-get emergency-enabled)
  })
