# NFT Artist Collective DAO

A decentralized autonomous organization (DAO) smart contract built on the Stacks blockchain, designed specifically for NFT artists to collaborate, govern their collective, and manage royalty distributions.

## Overview

This smart contract enables artists to form a collective where they can:
- Stake STX tokens to join the community
- Register and showcase their artworks
- Create and vote on creative proposals (exhibitions, collaborations, grants)
- Automatically distribute royalties from sales
- Build reputation through participation
- Self-govern through peer verification

## Features

### 🎨 Artist Management
- **Staking System**: Artists must stake a minimum of 5 STX to join
- **Specialization Tracking**: Artists can specify their specialty (digital, traditional, 3D, etc.)
- **Reputation System**: Build reputation through voting and artwork sales
- **Peer Verification**: Artists verify each other to maintain quality standards
- **Earnings Tracking**: Automatic tracking of total earnings from royalties

### 🖼️ Artwork Registry
- **Decentralized Storage**: Artworks linked via IPFS hashes
- **Categorization**: Organize artworks by category
- **Custom Royalties**: Set individual royalty rates (up to 10%)
- **Sales Analytics**: Track sales count and total revenue
- **Approval Process**: Community approval required for artwork listing

### 🗳️ Creative Governance
- **Proposal Types**: Support for exhibitions, collaborations, grants, and policy changes
- **Stake-Weighted Voting**: Voting power based on staked amount
- **Creative Feedback**: Voters can provide qualitative feedback on proposals
- **Automatic Finalization**: Proposals automatically finalize after voting period
- **Participation Requirements**: Minimum 30% participation rate for proposal validity

### 💰 Royalty Distribution
- **Automatic Splits**: Default 70% artist, 20% collective, 10% platform
- **Collaborator Support**: Support for up to 5 collaborators per artwork
- **Transparent Tracking**: All royalty distributions recorded on-chain
- **Flexible Structure**: Customizable royalty splits per artwork

## Contract Architecture

### Core Data Structures

#### Artists
```clarity
{
  joined-at: uint,           // Block height when joined
  stake-amount: uint,        // Amount of STX staked
  artworks-created: uint,    // Number of artworks registered
  votes-cast: uint,          // Participation in governance
  reputation: uint,          // Community reputation score
  specialty: string,         // Artist's specialty area
  is-verified: bool,         // Peer verification status
  total-earnings: uint       // Lifetime earnings from royalties
}
```

#### Artworks
```clarity
{
  title: string,            // Artwork title
  artist: principal,        // Creator's address
  created-at: uint,         // Registration block height
  price: uint,              // Set price in STX
  royalty-percentage: uint, // Custom royalty rate
  category: string,         // Artwork category
  is-approved: bool,        // Community approval status
  sales-count: uint,        // Number of sales
  total-revenue: uint,      // Total revenue generated
  ipfs-hash: string         // IPFS content hash
}
```

#### Proposals
```clarity
{
  title: string,           // Proposal title
  description: string,     // Detailed description
  proposal-type: string,   // Type: exhibition, collaboration, etc.
  proposer: principal,     // Who created the proposal
  vote-start: uint,        // Voting start block
  vote-end: uint,          // Voting end block
  yes-votes: uint,         // Total yes vote weight
  no-votes: uint,          // Total no vote weight
  status: string,          // active, passed, failed
  budget-requested: uint,  // Budget needed
  target-artists: uint,    // Number of artists needed
  venue: string            // Exhibition venue (optional)
}
```

## Key Functions

### Artist Functions

#### `join-collective`
Join the artist collective by staking STX tokens.
```clarity
(join-collective specialty stake-amount)
```
- `specialty`: Your artistic specialty (e.g., "digital", "3d", "traditional")
- `stake-amount`: Amount of STX to stake (minimum 5 STX)

#### `register-artwork`
Register a new artwork with the collective.
```clarity
(register-artwork title price category ipfs-hash custom-royalty-rate)
```

#### `verify-artist`
Verify another artist (requires being verified yourself).
```clarity
(verify-artist artist-to-verify)
```

### Governance Functions

#### `create-proposal`
Create a new proposal for collective consideration.
```clarity
(create-proposal title description proposal-type budget-requested target-artists venue)
```

#### `cast-vote`
Vote on an active proposal with optional creative feedback.
```clarity
(cast-vote proposal-id vote creative-feedback)
```

#### `finalize-proposal`
Finalize a proposal after voting period ends.
```clarity
(finalize-proposal proposal-id)
```

### Revenue Functions

#### `record-sale`
Record an artwork sale and distribute royalties.
```clarity
(record-sale artwork-id sale-price)
```

## Configuration

### Default Settings
- **Minimum Stake**: 5 STX
- **Voting Period**: 720 blocks (~5 days)
- **Default Royalty Rate**: 2.5%
- **Maximum Custom Royalty**: 10%
- **Minimum Participation**: 30% for proposal passage

### Royalty Distribution
- **Artist Share**: 70%
- **Collective Treasury**: 20%
- **Platform Fee**: 10%

## Deployment and Setup

1. **Deploy Contract**: Deploy to Stacks blockchain
2. **Initialize**: Call `initialize` function (contract owner only)
3. **Founder Setup**: Contract owner automatically joins as founder
4. **Artist Onboarding**: Artists can join via `join-collective`

## Governance Process

1. **Proposal Creation**: Verified artists create proposals
2. **Discussion Period**: 12-hour delay before voting starts
3. **Voting Period**: 5-day voting window
4. **Stake-Weighted Voting**: Votes weighted by stake amount
5. **Automatic Finalization**: Proposals finalize after voting ends
6. **Execution**: Passed proposals can be executed

## Security Features

- **Stake-Based Participation**: Prevents spam and ensures commitment
- **Peer Verification**: Community-driven quality control
- **Time-Locked Voting**: Prevents last-minute manipulation
- **Participation Thresholds**: Ensures legitimate community consensus
- **Error Handling**: Comprehensive error codes and validation

## Error Codes

- `u100`: Owner-only function
- `u101`: Not a verified artist
- `u102`: Artwork not found
- `u103`: Voting period closed
- `u104`: Already voted
- `u105`: Insufficient balance
- `u106`: Transfer failed
- `u107`: Invalid proposal
- `u108`: Not approved

## Use Cases

### Exhibitions
Create proposals for physical or virtual exhibitions, including venue, budget, and participating artists.

### Collaborations
Organize multi-artist collaborations with automatic royalty splitting among participants.

### Grants
Propose and vote on grants for emerging artists or specific projects.

### Policy Changes
Modify collective parameters like royalty rates, minimum stakes, or voting periods.

## Future Enhancements

- **Multi-token Support**: Accept other Stacks tokens for staking
- **Dynamic Royalty Adjustments**: Market-based royalty optimization
- **Enhanced Reputation System**: More sophisticated scoring algorithms
- **Cross-Chain Integration**: Support for Bitcoin NFTs via Stacks
- **Marketplace Integration**: Direct sales through the contract

## Contributing

This is an open-source project. Contributors should follow these guidelines:
1. Verify all changes through comprehensive testing
2. Maintain backward compatibility when possible
3. Document any new features or changes
4. Follow Clarity coding best practices

