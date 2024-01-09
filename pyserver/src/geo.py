# import typing

def dmsToDeg(gpsInfo) -> tuple[float,float]:
    latSign = 1 if gpsInfo[1] == 'N' else -1
    latValues = [float(x)/float(y) for x, y in gpsInfo[2]]
    lngSign = 1 if gpsInfo[3] == 'E' else -1
    lngValues = [float(x)/float(y) for x, y in gpsInfo[4]]
    latVal: float = latValues[0] + latValues[1]/60 + latValues[2]/3600
    lngVal: float = lngValues[0] + lngValues[1]/60 + lngValues[2]/3600
    return latVal*latSign,lngVal*lngSign

async def getLocation(long: float,lat: float)->str|None:
    pass

def trimLocation(location:str)->str:
    return location
