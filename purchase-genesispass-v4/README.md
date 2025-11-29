# Purchase Genesis Pass V4

This transaction allows users to purchase a Genesis Library Pass NFT from the NFTStorefrontV2 marketplace using DapperUtilityCoin (DUC).

## Overview

Genesis Library Pass is a lifetime access pass to the Published NFT library ecosystem, providing access to 2,000+ books, audiobooks, magazines, and exclusive content.

## Transaction Details

- **Contract**: GenesisPassV4
- **Contract Address (Testnet)**: 0x4c55dc21a9da7476
- **Payment Token**: DapperUtilityCoin (DUC)
- **Marketplace**: NFTStorefrontV2

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| storefrontAddress | Address | Address of the NFT seller's storefront |
| listingResourceID | UInt64 | ID of the listing to purchase |
| commissionRecipient | Address? | Optional commission recipient address |

## Features

- Auto-initializes buyer's NFT collection if needed
- Supports optional commission payments
- DUC leakage protection via post-condition
- MetadataViews compliant for proper NFT display

## Files

- `purchase-genesispass-v4.cdc` - Main purchase transaction
- `purchase-genesispass-v4-metadata.cdc` - Metadata script for purchase preview
- `testnet.env` - Testnet contract addresses

## Security

- All DUC must remain in Dapper's vault (no leakage)
- Collection auto-initialization prevents failed deposits
- Commission recipient validation ensures proper capability
