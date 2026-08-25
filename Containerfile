name: Build and publish image

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  DEFAULT_TAG: latest
  IMAGE_DESCRIPTION: "Sazid's personal bootc Open Image"
  IMAGE_NAME: ${{ github.event.repository.name }}
  IMAGE_REGISTRY: ghcr.io/${{ github.repository_owner }}

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-push:
    name: Build and publish
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      packages: write
    steps:
      - name: Normalize image metadata
        run: |
          echo "IMAGE_NAME=${IMAGE_NAME,,}" >> "${GITHUB_ENV}"
          echo "IMAGE_REGISTRY=${IMAGE_REGISTRY,,}" >> "${GITHUB_ENV}"
          echo "IMAGE_TAGS=${DEFAULT_TAG} sha-${GITHUB_SHA}" >> "${GITHUB_ENV}"

      - name: Checkout
        uses: actions/checkout@v6

      - name: Free build space
        uses: ublue-os/remove-unwanted-software@695eb75bc387dbcd9685a8e72d23439d8686cba6

      - name: Build image
        run: |
          TAGS=""
          for tag in ${{ env.IMAGE_TAGS }}; do
            TAGS="$TAGS -t localhost/${{ env.IMAGE_NAME }}:$tag"
          done
          
          sudo podman build \
            $TAGS \
            --label "org.opencontainers.image.title=${{ env.IMAGE_NAME }}" \
            --label "org.opencontainers.image.description=${{ env.IMAGE_DESCRIPTION }}" \
            --label "org.opencontainers.image.source=https://github.com/${{ github.repository }}" \
            --label "org.opencontainers.image.revision=${{ github.sha }}" \
            --label "containers.bootc=1" \
            --file ./Containerfile .

      - name: Push image
        run: |
          echo "${{ secrets.GITHUB_TOKEN }}" | sudo podman login -u ${{ github.actor }} --password-stdin ${{ env.IMAGE_REGISTRY }}
          for tag in ${{ env.IMAGE_TAGS }}; do
            sudo podman push localhost/${{ env.IMAGE_NAME }}:$tag ${{ env.IMAGE_REGISTRY }}/${{ env.IMAGE_NAME }}:$tag
          done

      - name: Print image reference
        run: |
          echo "Published ${{ env.IMAGE_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.DEFAULT_TAG }}"
