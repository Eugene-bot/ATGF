USE [AG_Data]
GO
/****** Object:  StoredProcedure [dbo].[addCoordRecord]    Script Date: 28.10.2019 9:18:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[addCoordRecord] 
@DeviceID INT ,
@DataDateTime DateTime, 
@ValidTime INT, 
@Power INT , 
@ReservPower INT , 
@Antenna1 INT , @Antenna2 INT ,
@In1 INT ,@In2 INT ,@In3 INT ,@In4 INT ,@In5 INT ,@In6 INT ,@In7 INT ,@In8 INT ,
@Flag1 INT ,@Flag2 INT, @Flag3 INT ,@Flag4 INT ,@Flag5 INT ,@Flag6 INT ,@Flag7 INT ,@Flag8 INT,
@Latitude float, @Longtitude float, 
@lnHDOP INT, @HDOP INT, 
@Source INT, 
@SatCount INT, 
@Speed float, 
@Azimut INT, 
@Altitude INT 
AS 
BEGIN 
SET NOCOUNT ON;
INSERT INTO Flags (DeviceID ,DataDateTime ,ValidTime , Power ,ReservPower ,Antenna1 ,Antenna2 ,
In1 ,In2 ,In3 ,In4 ,In5 ,In6 ,In7 ,In8 ,Flag1 ,Flag2, Flag3 ,Flag4 ,Flag5 ,Flag6 ,Flag7 ,Flag8)
OUTPUT 
@DeviceID, INSERTED.ID, @DataDateTime, @Latitude, @Longtitude, @lnHDOP, @HDOP, @ValidTime, @Source, @Power ,@ReservPower ,
@Antenna1 ,@Antenna2, @SatCount, @Speed, @Azimut, @Altitude, 
@In1 ,@In2 ,@In3 ,@In4 ,@In5 ,@In6 ,@In7 ,@In8 , @Flag1 ,@Flag2 ,@Flag3 ,@Flag4 ,@Flag5 ,@Flag6 ,@Flag7 ,@Flag8,DATEADD(hour, -3, CURRENT_TIMESTAMP)  	
INTO [Coordinate] (DeviceID, FlagsId, DataDateTime, Latitude, Longtitude ,lnHDOP ,HDOP ,ValidTime ,Source ,Power ,ReservPower, Antenna1, Antenna2,
SatCount, Speed ,Azimut ,Altitude ,In1 ,In2 ,In3 ,In4 ,In5 ,In6 ,In7 ,In8 ,Flag1 ,Flag2, Flag3 ,Flag4 ,Flag5 ,Flag6 ,Flag7 ,Flag8, CurrentDateTime) 
VALUES (@DeviceID ,@DataDateTime ,@ValidTime ,@Power ,@ReservPower ,@Antenna1 ,@Antenna2 ,
@In1 ,@In2 ,@In3 ,@In4 ,@In5 ,@In6 ,@In7 ,@In8 ,@Flag1 ,@Flag2 ,@Flag3 ,@Flag4 ,@Flag5 ,@Flag6 ,@Flag7 ,@Flag8); 

END;

/*	Добавил Шишкин 09.10.2019.
	Определяем и фиксируем геозону прибора.
*/
--/*
BEGIN --{  
declare @startime datetime = CURRENT_TIMESTAMP

declare @geoID int = 0, @oldGeozone int = 0
--declare @id int	
declare @PointInPoligon int = 0
declare @isInGeozone int = 0

-- Получим последнее местонахождение прибора:
select @oldGeozone = GeoID from DevicesInGeozones where DeviceID = @DeviceID order by id
if @oldGeozone is null set @oldGeozone = 0
-- Определяем, попадают ли координаты в прямоугольник какой-либо геозоны.
-- Для каждой из этих геозон определяем, входит ли в нее точка с координатами или нет.
select top 1 @geoID = ID FROM dbo.Geozones where @Latitude >= lat_min and @Latitude <= lat_max and @Longtitude >= long_min and @Longtitude <= long_max order by id
while @@rowcount > 0
begin
	set @isInGeozone = 0
	exec inPoligon @Longtitude, @Latitude, @geoid, @isInGeozone output
	
	if @isInGeozone = 1 -- прибор попал в геозону
	begin
		set @PointInPoligon = 1 -- установим этот флаг в единицу, чтобы далее не попасть в "нулевую" геозону
		
		-- Если последнее местонахождение не совпадает с новым - добавляем запись в таблицу DevicesInGeozones:
		if @geoID <> @oldGeozone
		insert into DevicesInGeozones(DeviceID, GeoID, DataDateTime, currTime, duration,latitude, longtitude) 
		values (@DeviceID, @geoID, @DataDateTime, DATEADD(hour, -3, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP - @startime, @Latitude, @Longtitude)
	end

	select top 1 @geoID=ID FROM dbo.Geozones where @Latitude >= lat_min and @Latitude <= lat_max and @Longtitude >= long_min and @Longtitude <= long_max and ID > @geoID order by id
end

-- Если после всех проверок оказалось, что прибор не находится ни в одной геозоне, помещаем его в "нулевую" геозону:
if @PointInPoligon = 0 and @oldGeozone <> 0
	insert into DevicesInGeozones(DeviceID, GeoID, DataDateTime, currTime, duration, latitude, longtitude) 
	values (@DeviceID, 0, @DataDateTime, DATEADD(hour, -3, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP - @startime, @Latitude, @Longtitude)
	
END --} определяем и фиксируем геозону прибора 