Once you have created the Automator application, you will need to do the following steps:

1. Add the following to First Boot Package Install Generator.app/Contents/Resources:

* application_source_components_and_graphics/pre-built_components/installer_build_components.tgz
* application_source_components_and_graphics/pre-built_components/xmlstarlet.tgz

2. Unzip the following files:

* application_source_components_and_graphics/icon/folder_icon.zip
* application_source_components_and_graphics/icon/application_icons.zip

3. Give the Automator application the First Boot Package Install Generator.app folder icon.

4. Go into First Boot Package Install Generator.app/Contents/Resources and remove the following file:

AutomatorApplet.icns

5. Rename the unzipped application_icons.zip file to be AutomatorApplet.icns and copy it to First Boot Package Install Generator.app/Contents/Resources.

6. Create a new installer package for First Boot Package Install Generator.app by using Simple Package Creator.app.