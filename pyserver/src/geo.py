# import typing
import math
import requests

def dmsToDeg(gpsInfo) -> tuple[float,float]:
    latSign = 1 if gpsInfo[1] == 'N' else -1
    latValues = gpsInfo[2]
    lngSign = 1 if gpsInfo[3] == 'E' else -1
    lngValues = gpsInfo[4]
    latVal: float = latValues[0] + latValues[1]/60 + latValues[2]/3600
    lngVal: float = lngValues[0] + lngValues[1]/60 + lngValues[2]/3600
    return latVal*latSign,lngVal*lngSign


async def getLocation(long: float,lat: float)->str|None:
    sess = GeocodingSession()
    return await sess.getLocation(long,lat)

def trimLocation(location:str)->str:
    return location

##  Created again by Chris on 8/3/2024 in python
## Created by Chris on 8/10/2018.
## Purpose: To reverse geocode from camera latitude/longitude to displayable name
##

class GeocodingSession:
    host: str = 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=14'
    cache: dict[str, str] = {}


    def  calcKey(self, longitude: float, latitude: float) -> str:
        tileSizeKms: float = 5.0
        latDegree: float  = 111.0
        longDegree: float  = 111.0 * math.cos(latitude * math.pi / 180)
        latTiles: int = int(latitude * latDegree / tileSizeKms)
        longTiles: int = int(longitude * longDegree / tileSizeKms)
        print(f'Geo-key {longTiles}:{latTiles} for ({longitude},{latitude})')
        return f'{longTiles}:{latTiles}'
        # of _calcKey

    def length(self) -> int: 
       return len(GeocodingSession.cache)

    async def getLocation(self, longitude: float, latitude: float) -> str|None: 
        key: str  = self.calcKey(longitude, latitude)
        if not key in GeocodingSession.cache.keys():
            newLocation: str  = await self.urlLookupFromCoordinates(latitude, longitude)
            GeocodingSession.cache[key] = newLocation
        return GeocodingSession.cache[key]
   # of getLocation

    def removeDiacritics(self, loc: str) -> str:
        withDia =    'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽžĀāĒēĪīŌōŪūþ'
        withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZzAaEeIiOoUup'
        for i,fromCh in enumerate(withDia): 
           loc = loc.replace(fromCh, withoutDia[i])
        return loc
    # of removeDiacritics

    def setLocation(self,longitude: float, latitude:float,location: str): 
        key = self.calcKey(longitude, latitude)
        GeocodingSession.cache[key] = location
    # of setLocation

    async def urlLookupFromCoordinates(self,latitude: float, longitude: float) -> str: 
        url: str = f'{GeocodingSession.host}&lat={latitude}&lon={longitude}'
        print('Sending {url}...')
        response = requests.get(url)
        if response.status_code != 200:
            raise Exception(f'openstreetmap lookup failed: \n {response.content}')
        data = response.json()
        result: str|None = data['display_name']
        if (result is not None): 
            return self.removeDiacritics(result)
        else: 
            raise Exception('Bad openstreetmap response format \n {response.content}')
    # of urlLookupFromCoordinates
# of GeocodingSession
