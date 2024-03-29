USE [AG_Data]
GO
/****** Object:  StoredProcedure [dbo].[inPoligon]    Script Date: 16.10.2019 10:51:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[inPoligon] 
	-- Add the parameters for the stored procedure here
	@coord_x float, -- Longitude 
	@coord_y float, -- Latitude
	@geoID int,  -- id геозоны, принадлежность к которой проверяем
	@result int = 0 output -- результат: 0 - точка с координатами не принадлежит геозоне; 1 - принадлежит
AS

BEGIN

SET NOCOUNT ON;

declare @long_x_prev float -- значение предыдущей записи
declare @lat_y_prev float -- значение предыдущей записи
declare @long_x float -- значение текущей записи
declare @lat_y float -- значение текущей записи
declare @id int

select @lat_y_prev = latitude, @long_x_prev = longitude from GeozonesBoundaries where GeoID = @geoID order by ID

select top 1 @id = ID, @lat_y = latitude, @long_x = longitude from GeozonesBoundaries where GeoID = @geoID order by ID
while @@rowcount > 0
begin
	if 
	(
		(((@lat_y <= @coord_y) and (@coord_y < @lat_y_prev)) or ((@lat_y_prev <= @coord_y) and (@coord_y < @lat_y))) 
		and								
		(@coord_x > (@long_x_prev - @long_x) * (@coord_y - @lat_y) / (@lat_y_prev - @lat_y) + @long_x)	
	)
	begin
		set @result = 1 - @result
	end
	
	set @lat_y_prev = @lat_y; set @long_x_prev = @long_x;
	
	select top 1 @id = ID, @lat_y = latitude, @long_x = longitude from GeozonesBoundaries where GeoID = @geoID and ID > @id order by ID
end
END