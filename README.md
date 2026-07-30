# Amplify Fusion CLI Scripts

This repo is a collection of example scripts using the [Axway Fusion CLI](https://docs.axway.com/bundle/amplify_integration/page/docs/fusion_cli/index.html).

Use for learning, demonstrations or modify for your needs.

Instructions:
* Import Fusion project zip file and configure as necessary
* Update the shell script as necessary
* Make script executable using `chmod +x deploy_LBclitest2_to_LIVE.sh`
* Read the script comments and set environment variables as necessary
* Run script `./deploy_LBclitest2_to_LIVE.sh`

Here's what's included so far:

* Promote Integration Project To Live Script
  * Fusion sample project and bash script to promote a project with one integration from DESIGN to LIVE after developer versions project
  * Does not include connection override
  * Tested with Fusion version 1.17.0 and CLI version 1.0.0
* Promote API Project To Live Script
  * Fusion sample project and bash script to promote a project with one API from DESIGN to LIVE after developer versions project
  * Does not include connection override
  * Tested with Fusion version 1.17.0 and CLI version 1.0.0
  * [Demo video](https://youtu.be/eOy_qFYg6GY)