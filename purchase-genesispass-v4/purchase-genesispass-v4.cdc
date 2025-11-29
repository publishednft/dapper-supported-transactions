import FungibleToken from ${FungibleToken}
import NonFungibleToken from ${NonFungibleToken}
import MetadataViews from ${MetadataViews}
import DapperUtilityCoin from ${DapperUtilityCoin}
import NFTStorefrontV2 from ${NFTStorefrontV2}
import ${NFTContractName} from ${NFTContractAddress}

transaction(storefrontAddress: Address, listingResourceID: UInt64, commissionRecipient: Address?) {

    let mainVault: auth(FungibleToken.Withdraw) &DapperUtilityCoin.Vault
    let paymentVault: @{FungibleToken.Vault}
    let nftReceiver: &{NonFungibleToken.Receiver}
    let storefront: &{NFTStorefrontV2.StorefrontPublic}
    let listing: &{NFTStorefrontV2.ListingPublic}
    let balanceBeforeTransfer: UFix64
    var commissionRecipientCap: Capability<&{FungibleToken.Receiver}>?

    prepare(dapper: auth(BorrowValue) &Account, buyer: auth(Storage, Capabilities) &Account) {
        self.commissionRecipientCap = nil

        if buyer.capabilities.borrow<&${NFTContractName}.Collection>(${NFTContractName}.CollectionPublicPath) == nil {
            let collection <- ${NFTContractName}.createEmptyCollection(nftType: Type<@${NFTContractName}.NFT>())
            buyer.storage.save(<-collection, to: ${NFTContractName}.CollectionStoragePath)

            let collectionCap = buyer.capabilities.storage.issue<&${NFTContractName}.Collection>(${NFTContractName}.CollectionStoragePath)
            buyer.capabilities.publish(collectionCap, at: ${NFTContractName}.CollectionPublicPath)
        }

        self.storefront = getAccount(storefrontAddress).capabilities.borrow<&{NFTStorefrontV2.StorefrontPublic}>(
                NFTStorefrontV2.StorefrontPublicPath
            ) ?? panic("Could not borrow Storefront from provided address")

        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No Offer with that ID in Storefront")
        let price = self.listing.getDetails().salePrice

        self.mainVault = dapper.storage.borrow<auth(FungibleToken.Withdraw) &DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault)
            ?? panic("Cannot borrow DapperUtilityCoin vault from acct storage")
        self.balanceBeforeTransfer = self.mainVault.balance
        self.paymentVault <- self.mainVault.withdraw(amount: price)

        let collectionData = ${NFTContractName}.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?
            ?? panic("ViewResolver does not resolve NFTCollectionData view")
        self.nftReceiver = buyer.capabilities.borrow<&{NonFungibleToken.Receiver}>(collectionData.publicPath)
            ?? panic("Cannot borrow NFT collection receiver from account")

        let commissionAmount = self.listing.getDetails().commissionAmount

        if commissionRecipient != nil && commissionAmount != 0.0 {
            let _commissionRecipientCap = getAccount(commissionRecipient!).capabilities.get<&{FungibleToken.Receiver}>(
                    /public/dapperUtilityCoinReceiver
                )
            assert(_commissionRecipientCap.check(), message: "Commission Recipient doesn't have DapperUtilityCoin receiving capability")
            self.commissionRecipientCap = _commissionRecipientCap
        } else if commissionAmount == 0.0 {
            self.commissionRecipientCap = nil
        } else {
            panic("Commission recipient can not be empty when commission amount is non zero")
        }
    }

    post {
        self.mainVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault,
            commissionRecipient: self.commissionRecipientCap
        )
        self.nftReceiver.deposit(token: <-item)
    }
}
