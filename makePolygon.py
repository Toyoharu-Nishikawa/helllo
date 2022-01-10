import os
import numpy as np
import matplotlib.pyplot as plt
import geojsoncontour
import json

def readData(csvPath):
    data = np.loadtxt(csvPath, delimiter=',')

    return data

def createGeoDic(Lat, Lng, Z, minLevel, targetLevel, maxLevel):
    interval = np.array([minLevel, targetLevel, maxLevel])
    contour = plt.contourf(Lng, Lat, Z,interval, cmap="jet")
    plt.colorbar(contour) 
    plt.gca().set_aspect('equal')
    
    geojson = geojsoncontour.contourf_to_geojson(
        contourf=contour,
        ndigits=3,
        unit='m'
    )

    d =json.loads(geojson)
    dd={
        "type":"FeatureCollection",
        "features":[d["features"][1]],
    }
    
    return dd


def makeFunc(Lat, Lng, Z, minLevel, maxLevel):
    def f(targetLevel):
        return createGeoDic(Lat, Lng, Z, minLevel, targetLevel, maxLevel)
    return f     
 
class MakePolygon:
    def __init__(self, data, M, N, targetLevel):
        self.data = None
        self.M = None
        self.M = None
        self.N = None
        self.targetLevelArray = None
        self.Lat = None
        self.Lng = None
        self.Z = None
        self.maxLevel = None
        self.minLevel = None
        self.geoData = None

        self.setParameters(data, M, N, targetLevel)

    def setParameters(self,data, M, N, targetLevel):
        self.data = data
        self.M = M
        self.N = N
  
        if type(targetLevel) is float:
            self.targetLevelArray = np.array([targetLevel])
        elif type(targetLevel) is int:
            self.targetLevelArray = np.array([targetLevel]) 
        elif type(targetLevel) is list:
            self.targetLevelArray = np.array(targetLevel) 
        elif type(targetLevel).__module__ =="numpy":
            self.targetLevelArray = targetLevel
        else:
            raise ValueError("target leve must be int, float, list, or numpy arra")
  
    
    def parseData(self):
        data = self.data
        M = self.M
        N = self.N

        lat= data[:,0]
        lng = data[:,1]
        z= data[:,2]
        
        maxLevel = np.max(z)
        minLevel = np.min(z)
        
        
        Lat = lat.reshape(N,M)
        Lng = lng.reshape(N,M)
        Z = z.reshape(N,M)
    
        self.Lat = Lat
        self.Lng = Lng
        self.Z = Z
        self.maxLevel = maxLevel
        self.minLevel = minLevel
    

    def create(self):
        self.parseData() 

        Lat = self.Lat
        Lng = self.Lng
        Z = self.Z
        minLevel = self.minLevel
        maxLevel = self.maxLevel
        targetLevelArray = self.targetLevelArray

        cFunc = makeFunc(Lat, Lng, Z, minLevel, maxLevel)
        vFunc = np.vectorize(cFunc)
        geoData = vFunc(targetLevelArray)
        self.geoData = geoData

    def getGeojson():
        return self.geoData

    
    def saveGeojson(self, savePath,fileNamePrefix):
        geoData = self.geoData
        targetLevelArray = self.targetLevelArray

        count = 0
        for d in geoData:
            targetLevel = targetLevelArray[count] 
            eachFileName = fileNamePrefix + "_" + str(targetLevel) + ".geojson"
            contourFile = os.path.join(savePath, eachFileName)
            with open(contourFile, 'w') as f:
                json.dump(d,f)
            count+=1
            print("save",contourFile)


def main():
    N = 10
    M = 10

    csvPath = "./LatLngLevel.csv"
    savePath = "./"
    fileNamePrefix = "contour"
    targetLevelArray = np.array([0.5, 0.8, 1.0])

    data = readData(csvPath)

    makePolygon = MakePolygon(data, M, N, targetLevelArray)
    makePolygon.create()
    makePolygon.saveGeojson(savePath, fileNamePrefix)


if __name__ == '__main__':
    print('call main()')
    main()
