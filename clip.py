
############### initialize ######################

import os
import sys


os.environ['QT_QPA_PLATFORM_PLUGIN_PATH'] = r"C:\OSGeo4W64\apps\Qt5\plugins"
os.environ['GDAL_DATA'] = r"C:/OSGeo4W64/share/gdal"
os.environ["PROJ_LIB"]= r"C:/OSGeo4W64/share/proj"
sys.path.append(r"C:\OSGeo4W64\apps\qgis\python")
sys.path.append(r"C:\OSGeo4W64\apps\qgis\python\plugins")
sys.path.append(r"C:\OSGeo4W64\apps\Python37\lib\site-packages")


from qgis.core import *
from qgis.analysis import QgsNativeAlgorithms



QgsApplication.setPrefixPath(r"C:\OSGeo4W64\apps\qgis",True) 

qgs = QgsApplication([], False)
qgs.initQgis()

print("show settings")
print(QgsApplication.showSettings())

from processing.core.Processing import Processing 
import processing

Processing.initialize()  # needed to be able to use the functions afterwards
QgsApplication.processingRegistry().addProvider(QgsNativeAlgorithms())

feedback = QgsProcessingFeedback()

project = QgsProject.instance()

############################ main ################

waterLevelURI = "C:/Users/contour0.8.geojson"
water_layer=QgsVectorLayer(waterLevelURI, "wawterLevel0.8", "ogr")
project.addMapLayer(water_layer)
print("water_layer")
print(water_layer.isValid())

japanURI = "C:/Users/N03-21_210101.shp"
japan = QgsVectorLayer(japanURI, "japan", "ogr")
print("japan")
print(japan.isValid())


clipOutput = "C:/Users/clip.geojson"
overlay = processing.run("native:clip", 
    {'INPUT':japan,'OVERLAY':water_layer,'OUTPUT': clipOutput},
    feedback = feedback)
print(overlay["OUTPUT"])


########################### close #################
qgs.exit()
qgs.exitQgis()
