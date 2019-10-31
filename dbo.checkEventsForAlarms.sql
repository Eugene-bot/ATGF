USE [AG_Data]
GO
/****** Object:  StoredProcedure [dbo].[checkEventsForAlarms]    Script Date: 31.10.2019 14:43:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
ALTER PROCEDURE [dbo].[checkEventsForAlarms] 
AS
BEGIN

SET NOCOUNT ON;

declare @id int
declare @slisedate datetime
declare @pos_id int

select top 1 @id = id, @slisedate = datadatetime, @pos_id = id_pos from [agro_fuel_level_alarm] where is_checked = 0 order by id
while @@ROWCOUNT > 0
begin
	
	exec checkDevicesInAZS @slisedate, @pos_id, @id
	
	select top 1 @id = id, @slisedate = datadatetime, @pos_id = id_pos from [agro_fuel_level_alarm] where is_checked = 0 and id > @id order by id
end 

END
