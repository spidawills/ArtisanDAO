;; NFT Artist Collective DAO Smart Contract
;; Specialized for creative governance and royalty distribution

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-artist (err u101))
(define-constant err-artwork-not-found (err u102))
(define-constant err-voting-closed (err u103))
(define-constant err-already-voted (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-transfer-failed (err u106))
(define-constant err-invalid-proposal (err u107))
(define-constant err-not-approved (err u108))

;; Data Variables
(define-data-var proposal-counter uint u0)
(define-data-var artist-counter uint u0)
(define-data-var artwork-counter uint u0)
(define-data-var min-stake uint u5000000) ;; 5 STX minimum stake
(define-data-var voting-period uint u720) ;; ~5 days in blocks
(define-data-var royalty-rate uint u250) ;; 2.5% default royalty

;; Artist Management
(define-map artists
  principal
  {
    joined-at: uint,
    stake-amount: uint,
    artworks-created: uint,
    votes-cast: uint,
    reputation: uint,
    specialty: (string-ascii 50), ;; digital, traditional, 3d, etc.
    is-verified: bool,
    total-earnings: uint
  }
)

;; Artwork Registry
(define-map artworks
  uint
  {
    title: (string-ascii 100),
    artist: principal,
    created-at: uint,
    price: uint,
    royalty-percentage: uint,
    category: (string-ascii 30),
    is-approved: bool,
    sales-count: uint,
    total-revenue: uint,
    ipfs-hash: (string-ascii 100)
  }
)

;; Creative Proposals (exhibitions, collaborations, etc.)
(define-map proposals
  uint
  {
    title: (string-ascii 100),
    description: (string-utf8 1000),
    proposal-type: (string-ascii 30), ;; exhibition, collaboration, grant, policy
    proposer: principal,
    created-at: uint,
    vote-start: uint,
    vote-end: uint,
    yes-votes: uint,
    no-votes: uint,
    total-voters: uint,
    status: (string-ascii 20),
    budget-requested: uint,
    target-artists: uint,
    venue: (optional (string-ascii 100))
  }
)

;; Vote records
(define-map votes
  {proposal-id: uint, voter: principal}
  {
    vote: (string-ascii 10),
    stake-power: uint,
    timestamp: uint,
    creative-feedback: (optional (string-utf8 300))
  }
)

;; Royalty Distribution
(define-map royalty-splits
  uint ;; artwork-id
  {
    artist-share: uint,
    collective-share: uint,
    platform-share: uint,
    collaborators: (list 5 principal),
    collaborator-shares: (list 5 uint)
  }
)

;; Artist Functions
(define-public (join-collective (specialty (string-ascii 50)) (stake-amount uint))
  (let ((artist-id (+ (var-get artist-counter) u1)))
    (asserts! (is-none (map-get? artists tx-sender)) err-not-artist)
    (asserts! (>= stake-amount (var-get min-stake)) err-insufficient-balance)
    (asserts! (>= (stx-get-balance tx-sender) stake-amount) err-insufficient-balance)
    
    ;; Transfer stake
    (unwrap! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)) err-transfer-failed)
    
    (map-set artists tx-sender {
      joined-at: block-height,
      stake-amount: stake-amount,
      artworks-created: u0,
      votes-cast: u0,
      reputation: u100,
      specialty: specialty,
      is-verified: false,
      total-earnings: u0
    })
    
    (var-set artist-counter artist-id)
    (print {event: "artist-joined", artist: tx-sender, specialty: specialty, stake: stake-amount})
    (ok artist-id)
  )
)

;; Register Artwork
(define-public (register-artwork 
  (title (string-ascii 100))
  (price uint)
  (category (string-ascii 30))
  (ipfs-hash (string-ascii 100))
  (custom-royalty-rate uint))
  
  (let ((artwork-id (+ (var-get artwork-counter) u1))
        (artist-data (unwrap! (map-get? artists tx-sender) err-not-artist)))
    
    (asserts! (get is-verified artist-data) err-not-approved)
    (asserts! (<= custom-royalty-rate u1000) err-invalid-proposal) ;; Max 10% royalty
    
    (map-set artworks artwork-id {
      title: title,
      artist: tx-sender,
      created-at: block-height,
      price: price,
      royalty-percentage: (if (> custom-royalty-rate u0) custom-royalty-rate (var-get royalty-rate)),
      category: category,
      is-approved: false,
      sales-count: u0,
      total-revenue: u0,
      ipfs-hash: ipfs-hash
    })
    
    ;; Set default royalty split
    (map-set royalty-splits artwork-id {
      artist-share: u7000, ;; 70%
      collective-share: u2000, ;; 20%
      platform-share: u1000, ;; 10%
      collaborators: (list),
      collaborator-shares: (list)
    })
    
    ;; Update artist stats
    (map-set artists tx-sender 
      (merge artist-data {artworks-created: (+ (get artworks-created artist-data) u1)}))
    
    (var-set artwork-counter artwork-id)
    (print {event: "artwork-registered", artwork-id: artwork-id, artist: tx-sender, category: category})
    (ok artwork-id)
  )
)

;; Create Creative Proposal
(define-public (create-proposal 
  (title (string-ascii 100))
  (description (string-utf8 1000))
  (proposal-type (string-ascii 30))
  (budget-requested uint)
  (target-artists uint)
  (venue (optional (string-ascii 100))))
  
  (let ((proposal-id (+ (var-get proposal-counter) u1))
        (artist-data (unwrap! (map-get? artists tx-sender) err-not-artist)))
    
    (asserts! (get is-verified artist-data) err-not-artist)
    
    (map-set proposals proposal-id {
      title: title,
      description: description,
      proposal-type: proposal-type,
      proposer: tx-sender,
      created-at: block-height,
      vote-start: (+ block-height u72), ;; ~12 hours delay
      vote-end: (+ block-height (+ u72 (var-get voting-period))),
      yes-votes: u0,
      no-votes: u0,
      total-voters: u0,
      status: "active",
      budget-requested: budget-requested,
      target-artists: target-artists,
      venue: venue
    })
    
    (var-set proposal-counter proposal-id)
    (print {event: "proposal-created", proposal-id: proposal-id, type: proposal-type, budget: budget-requested})
    (ok proposal-id)
  )
)

;; Cast Vote with Creative Feedback
(define-public (cast-vote 
  (proposal-id uint)
  (vote (string-ascii 10))
  (creative-feedback (optional (string-utf8 300))))
  
  (let ((proposal (unwrap! (map-get? proposals proposal-id) err-invalid-proposal))
        (artist-data (unwrap! (map-get? artists tx-sender) err-not-artist))
        (stake-power (get stake-amount artist-data)))
    
    (asserts! (get is-verified artist-data) err-not-artist)
    (asserts! (>= block-height (get vote-start proposal)) err-voting-closed)
    (asserts! (< block-height (get vote-end proposal)) err-voting-closed)
    (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) err-already-voted)
    (asserts! (or (is-eq vote "yes") (is-eq vote "no")) err-invalid-proposal)
    
    ;; Record vote
    (map-set votes {proposal-id: proposal-id, voter: tx-sender} {
      vote: vote,
      stake-power: stake-power,
      timestamp: block-height,
      creative-feedback: creative-feedback
    })
    
    ;; Update proposal totals
    (let ((updated-yes (if (is-eq vote "yes") (+ (get yes-votes proposal) stake-power) (get yes-votes proposal)))
          (updated-no (if (is-eq vote "no") (+ (get no-votes proposal) stake-power) (get no-votes proposal))))
      
      (map-set proposals proposal-id 
        (merge proposal {
          yes-votes: updated-yes,
          no-votes: updated-no,
          total-voters: (+ (get total-voters proposal) u1)
        }))
    )
    
    ;; Update artist reputation
    (map-set artists tx-sender 
      (merge artist-data {
        votes-cast: (+ (get votes-cast artist-data) u1),
        reputation: (+ (get reputation artist-data) u2)
      }))
    
    (print {event: "vote-cast", proposal-id: proposal-id, voter: tx-sender, vote: vote})
    (ok true)
  )
)

;; Approve Artist (by other verified artists)
(define-public (verify-artist (artist-to-verify principal))
  (let ((verifier-data (unwrap! (map-get? artists tx-sender) err-not-artist))
        (target-data (unwrap! (map-get? artists artist-to-verify) err-not-artist)))
    
    (asserts! (get is-verified verifier-data) err-not-approved)
    (asserts! (not (get is-verified target-data)) err-invalid-proposal)
    
    (map-set artists artist-to-verify (merge target-data {is-verified: true}))
    (print {event: "artist-verified", artist: artist-to-verify, verifier: tx-sender})
    (ok true)
  )
)

;; Record Sale and Distribute Royalties
(define-public (record-sale (artwork-id uint) (sale-price uint))
  (let ((artwork (unwrap! (map-get? artworks artwork-id) err-artwork-not-found))
        (royalty-split (unwrap! (map-get? royalty-splits artwork-id) err-artwork-not-found))
        (artist-data (unwrap! (map-get? artists (get artist artwork)) err-not-artist)))
    
    ;; Calculate royalty amounts
    (let ((artist-royalty (/ (* sale-price (get artist-share royalty-split)) u10000))
          (collective-royalty (/ (* sale-price (get collective-share royalty-split)) u10000)))
      
      ;; Update artwork stats
      (map-set artworks artwork-id 
        (merge artwork {
          sales-count: (+ (get sales-count artwork) u1),
          total-revenue: (+ (get total-revenue artwork) sale-price)
        }))
      
      ;; Update artist earnings
      (map-set artists (get artist artwork)
        (merge artist-data {
          total-earnings: (+ (get total-earnings artist-data) artist-royalty),
          reputation: (+ (get reputation artist-data) u5)
        }))
      
      (print {event: "sale-recorded", artwork-id: artwork-id, price: sale-price, artist-royalty: artist-royalty})
      (ok true)
    )
  )
)

;; Finalize Proposal
(define-public (finalize-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) err-invalid-proposal)))
    (asserts! (>= block-height (get vote-end proposal)) err-voting-closed)
    (asserts! (is-eq (get status proposal) "active") err-invalid-proposal)
    
    (let ((total-stake-voted (+ (get yes-votes proposal) (get no-votes proposal)))
          (total-collective-stake (* (var-get artist-counter) (var-get min-stake)))
          (participation-rate (/ (* total-stake-voted u100) total-collective-stake))
          (proposal-passed (and (>= participation-rate u30) (> (get yes-votes proposal) (get no-votes proposal)))))
      
      (map-set proposals proposal-id 
        (merge proposal {status: (if proposal-passed "passed" "failed")}))
      
      (print {event: "proposal-finalized", proposal-id: proposal-id, passed: proposal-passed, participation: participation-rate})
      (ok proposal-passed)
    )
  )
)

;; Read-only functions
(define-read-only (get-artist (artist principal))
  (map-get? artists artist)
)

(define-read-only (get-artwork (artwork-id uint))
  (map-get? artworks artwork-id)
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-royalty-split (artwork-id uint))
  (map-get? royalty-splits artwork-id)
)

;; Initialize
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (unwrap! (join-collective "founder" (var-get min-stake)) err-not-artist)
    (unwrap! (verify-artist contract-owner) err-not-approved)
    (ok true)
  )
)