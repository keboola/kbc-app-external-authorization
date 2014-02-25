# kbc.app.External

Application injectable into Keboola Connection UI written in angular using angular-kb library created by [generator-kbc-ui-app](https://github.com/keboola/generator-kbc-ui-app)
Application defines all its dependencies including angular an jquery (see bower.json), any other dependencies can be added.




## Lifecycle of application

 * Implement new features or fix bugs in development mode
 * Build the package
 * Tag the version and update the changelog
 * Install application version to KBC

## Development

* Clone the repo
* Instal global dependencies `npm install -g grunt-cli bower`
* Install local dependencies `npm install && bower install --dev`
* Server, watch and test with live reload `grunt server`
* Server runs on `localhost:9000/`, you can provide Storage API token for testing `localhost:9000/?token=your_token`

Application is developed in mock layout then deployed to KBC.


## Build dist package

* `grunt` builds app into `dist` and `release` folder
  * `dist` minified version of mock application
    * You can test it locally `grunt server:dist`
  * `release` package prepared for deployment to KBC


## Install application to KBC
To be able to upload builded package to S3 you have to provide AWS credentials.
These credentials are fetched from `./aws-keys.json` file.

* git tag the version and update CHANGELOG.MD
* upload revision `grunt upload-release` to S3
* register new release in Keboola Connection administration - copy&paste manifest url produced by last step


Read more in [Keboola Public Project Guidelines](https://github.com/keboola/public-project-guidelines)