# Dockerfile for AWS Codebuild

This image is used as the base for the Apollo Server Codebuild that is used to run our database migrations. Because the Codebuild runs within the VPC, it does not have connectivity to the outside world, so we build the image with everything it needs.

To update the image, adjust the `Dockerfile` in this directory as needed and then run `src/codeBuild/build_publish.sh`

Once deployed, the next time the Apollo server Codepipeline runs, it should pick up the new image
