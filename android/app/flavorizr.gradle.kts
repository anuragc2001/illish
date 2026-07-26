import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.anuragchak.illish"
            resValue(type = "string", name = "app_name", value = "Illish")
        }
        create("exp") {
            dimension = "flavor-type"
            applicationId = "com.anuragchak.illish.dev"
            resValue(type = "string", name = "app_name", value = "Illish Dev")
        }
    }

    buildFeatures.resValues = true
}