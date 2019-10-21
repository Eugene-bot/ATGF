USE [AG_Data]
GO
/****** Object:  StoredProcedure [dbo].[checkDevicesInAZS]    Script Date: 21.10.2019 16:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[checkDevicesInAZS] 
	-- Add the parameters for the stored procedure here
	@slicedate datetime, 
	@pos_id int
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
set @slicedate = DATEADD(hour, -3, @slicedate) --приводим время к 0-му часовому поясу, т.к. Автограф передает в таблицу Coordinates такое же.
print convert (nvarchar, @slicedate)
declare @geoid int
select @geoid = id from Geozones where topaz_pos_id = @pos_id
print @geoid

-- получаем срез устройств на дату
select 
max(DataDateTime) DataDateTime, DeviceID DeviceID 
into #slice
from DevicesInGeozones
where DataDateTime <= @slicedate
group by DeviceID

-- соединяем с физической таблицей
select dig.DeviceID, dig.GeoID, dig.DataDateTime
into #dev
from DevicesInGeozones dig 
join #slice slc
	on dig.DeviceID = slc.DeviceID and dig.DataDateTime = slc.DataDateTime
where dig.GeoID = @geoid

DECLARE cursor_ CURSOR LOCAL FAST_FORWARD
for select deviceid, geoid, DataDateTime from #dev
open cursor_

declare @did int, @gid int, @ddt datetime

fetch cursor_ into @did, @gid, @ddt
while @@FETCH_STATUS = 0
begin
	print '----------------------------------------------------'
	print convert(nvarchar, @did)
	print convert(nvarchar, @gid)
	print convert(nvarchar, @ddt)
	
	fetch cursor_ into @did, @gid, @ddt
end

close cursor_

END
