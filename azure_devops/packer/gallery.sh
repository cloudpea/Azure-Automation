echo "In Gallery Script"

# Delete Current Image
echo "Shared Gallery - Deleting Image Version 1.0.0 $BASE_IMAGE_NAME"
az sig image-version delete -g $ARM_GALLERY_RG --gallery-name $ARM_GALLERY_NAME --gallery-image-definition $BASE_IMAGE_NAME --gallery-image-version 1.0.0
sleep 10

# Create New Image
echo "Shared Gallery - Creating Image Version 1.0.0 $BASE_IMAGE_NAME"
az sig image-version create -g $ARM_GALLERY_RG --gallery-name $ARM_GALLERY_NAME --gallery-image-definition $BASE_IMAGE_NAME --gallery-image-version 1.0.0 --target-regions "uksouth=2" "ukwest=1" --managed-image "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$ARM_MASTER_IMAGE_RG/providers/Microsoft.Compute/images/$ARM_IMAGE_NAME" --tags "source=$ARM_IMAGE_NAME"

echo "End Gallery Script"
echo ""