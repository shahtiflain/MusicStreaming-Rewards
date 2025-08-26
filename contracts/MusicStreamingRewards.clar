;; MusicStreaming Rewards Contract
;; A token-based reward system for music discovery and artist promotion

;; Define the reward token
(define-fungible-token music-reward-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-amount (err u101))
(define-constant err-already-rewarded (err u102))
(define-constant err-artist-not-found (err u103))
(define-constant err-insufficient-balance (err u104))

;; Token info
(define-data-var token-name (string-ascii 32) "Music Reward Token")
(define-data-var token-symbol (string-ascii 10) "MRT")
(define-data-var token-decimals uint u6)

;; Reward amounts
(define-constant discovery-reward u1000000) ;; 1 MRT
(define-constant promotion-reward u2000000) ;; 2 MRT

;; Data structures
(define-map listener-song-rewards 
  {listener: principal, song-id: (string-ascii 64)} 
  {rewarded: bool, timestamp: uint})

(define-map artist-promotions
  {promoter: principal, artist-id: (string-ascii 64)}
  {reward-amount: uint, timestamp: uint})

(define-data-var total-rewards-distributed uint u0)

;; Initialize rewards
(define-public (initialize-rewards (initial-supply uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> initial-supply u0) err-invalid-amount)
    (try! (ft-mint? music-reward-token initial-supply contract-owner))
    (ok true)
  )
)

;; Reward listeners for discovering new music
(define-public (reward-music-discovery (user principal) (song-id (string-ascii 64)) (artist-name (string-ascii 64)))
  (let
    (
      (reward-key {listener: user, song-id: song-id})
      (existing-reward (map-get? listener-song-rewards reward-key))
      (balance (ft-get-balance music-reward-token contract-owner))
    )
    (if (is-none existing-reward)
      (if (>= balance discovery-reward)
        (match (as-contract (ft-transfer? music-reward-token discovery-reward contract-owner user))
          success
            (begin
              (map-set listener-song-rewards reward-key {rewarded: true, timestamp: stacks-block-height})
              (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) discovery-reward))
              (print {
                event: "music-discovery-reward",
                listener: user,
                song-id: song-id,
                artist-name: artist-name,
                reward-amount: discovery-reward,
                block-height: stacks-block-height
              })
              (ok discovery-reward)
            )
          error (err error)
        )
        err-insufficient-balance
      )
      err-already-rewarded
    )
  )
)

;; Reward users for promoting artists
(define-public (reward-artist-promotion (user principal) (artist-id (string-ascii 64)) (platform (string-ascii 32)))
  (let
    (
      (promotion-key {promoter: user, artist-id: artist-id})
      (existing-promotion (map-get? artist-promotions promotion-key))
      (balance (ft-get-balance music-reward-token contract-owner))
    )
    (if (>= balance promotion-reward)
      (match (as-contract (ft-transfer? music-reward-token promotion-reward contract-owner user))
        success
          (begin
            (map-set artist-promotions promotion-key
              {reward-amount: (+ (default-to u0 (get reward-amount existing-promotion)) promotion-reward),
               timestamp: stacks-block-height})
            (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) promotion-reward))
            (print {
              event: "artist-promotion-reward",
              promoter: user,
              artist-id: artist-id,
              platform: platform,
              reward-amount: promotion-reward,
              block-height: stacks-block-height
            })
            (ok promotion-reward)
          )
        error (err error)
      )
      err-insufficient-balance
    )
  )
)

;; Read-only functions
(define-read-only (get-discovery-reward-status (listener principal) (song-id (string-ascii 64)))
  (map-get? listener-song-rewards {listener: listener, song-id: song-id})
)

(define-read-only (get-promotion-rewards (promoter principal) (artist-id (string-ascii 64)))
  (map-get? artist-promotions {promoter: promoter, artist-id: artist-id})
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance music-reward-token account))
)

(define-read-only (get-total-rewards-distributed)
  (ok (var-get total-rewards-distributed))
)

(define-read-only (get-token-info)
  (ok {
    name: (var-get token-name),
    symbol: (var-get token-symbol),
    decimals: (var-get token-decimals)
  })
)
