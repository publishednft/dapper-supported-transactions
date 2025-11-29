import NonFungibleToken from ${NonFungibleToken}
import MetadataViews from ${MetadataViews}
import NFTStorefrontV2 from ${NFTStorefrontV2}
import ${NFTContractName} from ${NFTContractAddress}

access(all) struct PurchaseData {
    access(all) let id: UInt64
    access(all) let name: String
    access(all) let amount: UFix64
    access(all) let description: String
    access(all) let imageURL: String
    access(all) let paymentVaultTypeID: Type

    init(id: UInt64, name: String, amount: UFix64, description: String, imageURL: String, paymentVaultTypeID: Type) {
        self.id = id
        self.name = name
        self.amount = amount
        self.description = description
        self.imageURL = imageURL
        self.paymentVaultTypeID = paymentVaultTypeID
    }
}

access(all) fun main(storefrontAddress: Address, listingResourceID: UInt64, commissionRecipient: Address?): PurchaseData {

    let account = getAccount(storefrontAddress)
    let marketCollectionRef = account.capabilities.get<&NFTStorefrontV2.Storefront>(
        NFTStorefrontV2.StorefrontPublicPath
    ).borrow()
    ?? panic("Could not borrow Storefront from provided address")

    let saleItem = marketCollectionRef.borrowListing(listingResourceID: listingResourceID)
        ?? panic("No item with that ID")

    let listingDetails = saleItem.getDetails()!

    let collection = account.capabilities.get<&{NonFungibleToken.Collection}>(
        ${NFTContractName}.CollectionPublicPath
    ).borrow()
    ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowNFT(listingDetails.nftID)
            ?? panic("Could not borrow a reference to the NFT")

    let viewSerial = nft.resolveView(Type<MetadataViews.Serial>())!
    let displaySerial = viewSerial as! MetadataViews.Serial

    if let view = nft.resolveView(Type<MetadataViews.Display>()) {

        let display = view as! MetadataViews.Display

        let purchaseData = PurchaseData(
            id: displaySerial.number,
            name: display.name,
            amount: listingDetails.salePrice,
            description: display.description,
            imageURL: display.thumbnail.uri(),
            paymentVaultTypeID: listingDetails.salePaymentVaultType
        )

        return purchaseData
    }
     panic("No NFT")
}
