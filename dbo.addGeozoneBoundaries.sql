USE [AG_Data]
GO
/****** Object:  StoredProcedure [dbo].[addGeozoneBoundaries]    Script Date: 15.10.2019 13:36:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
ALTER PROCEDURE [dbo].[addGeozoneBoundaries] 
	@AG_ID nchar(36), -- ИД геозоны из Автографа
	@AG_Name nchar(50), -- Имя геозоны
	@Coordinates NVARCHAR(max) -- строка с координатами
AS
BEGIN

SET NOCOUNT ON;

declare @id int -- id геозоны

-- Проверяем наличие поля (геозоны) и, если надо, добавляем его с возвращением идентификатор добавленной записи
exec selectGeozone @AG_ID, @id output
if @id is null 
begin 
	insert into Geozones(AG_ID, Name) values(@AG_ID, @AG_Name) SET @id = @@IDENTITY
end

-- Удаляем имеющиеся границы геозоны
delete from GeozonesBoundaries where GeoID = @id

-- Добавляем новые границы
declare @spaceLocation int, @currCoordinates nvarchar(100), @Coord nvarchar(3000)
while LEN(@Coordinates) > 0
begin
	SET @spaceLocation = PATINDEX('% %', @Coordinates)

	if @spaceLocation > 0 
		SET @currCoordinates = LEFT(@Coordinates, @spaceLocation - 1)
	else
		SET @currCoordinates = @Coordinates

	begin
		declare @lat float, @long float, @alt float(53)
		set @long = LEFT(@currCoordinates, PATINDEX('%,%', @currCoordinates) - 1)
		set @lat = LEFT(RIGHT(@currCoordinates, LEN(@currCoordinates) - PATINDEX('%,%', @currCoordinates)), PATINDEX('%,%', @currCoordinates) - 1)
		
		insert into GeozonesBoundaries(GeoID, Latitude, Longitude) values(@id, @lat, @long)
	end
		
	if @spaceLocation > 0
		SET @Coordinates = SUBSTRING(@Coordinates, @spaceLocation + 1, LEN(@Coordinates) - @spaceLocation)
	else
		SET @Coordinates = ''
end

-- Заполняем поля lat_min, lat_max, long_min, long_max таблицы Geozones
update Geozones set lat_min = gzb.lat_min, lat_max = gzb.lat_max, long_min = gzb.long_min , long_max = gzb.long_max
from (select min(Latitude) lat_min, max(Latitude) lat_max, min(Longitude) long_min, max(Longitude) long_max from GeozonesBoundaries  where GeoID = @id) gzb
where id = @id

END
