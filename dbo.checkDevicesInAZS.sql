USE [AG_Data]
GO
/****** Object:  StoredProcedure [dbo].[checkDevicesInAZS]    Script Date: 31.10.2019 15:17:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
ALTER PROCEDURE [dbo].[checkDevicesInAZS] 
/* ПАРАМЕТРЫ:
@slicedate: дата/время, по состоянию на которое определяется нахождение транспортных средств на АЗС
@pos_id : ИД АЗС (склада/точки продажи)
@event_id: ИД события, которое проверяется на аларм
*/

@slicedate datetime, 
@pos_id int,
@event_id int

AS
BEGIN

SET NOCOUNT ON;

set @slicedate = DATEADD(hour, -3, @slicedate) --приводим время к 0-му часовому поясу, т.к. Автограф передает в таблицу Coordinates в таком же часовом поясе.
--print convert (nvarchar, @slicedate)

declare @geoid int
select @geoid = id from Geozones where topaz_pos_id = @pos_id
--print @geoid

-- получаем срез устройств на дату
-- выбираем только те устройства, у которых актуальность координат - в пределах трех часов
declare @actualDate datetime
set @actualDate = DATEADD(hour, -3, @slicedate)
select max(DataDateTime) DataDateTime, DeviceID DeviceID 
into #slice
from DevicesInGeozones
where DataDateTime <= @slicedate and DataDateTime >= @actualDate
group by DeviceID

-- соединяем с физической таблицей
select dig.DeviceID, dig.GeoID, dig.DataDateTime
into #dev
from DevicesInGeozones dig 
join #slice slc
	on dig.DeviceID = slc.DeviceID and dig.DataDateTime = slc.DataDateTime
where dig.GeoID = @geoid

declare @did int, @gid int, @ddt datetime
declare @alarm numeric(1,0)

declare cursor_ cursor local fast_forward
for select deviceid, geoid, DataDateTime from #dev
open cursor_
fetch cursor_ into @did, @gid, @ddt

if @@FETCH_STATUS = 0 -- устройства обнаружены
	set @alarm = 0
else
	set @alarm = 1

--print 'is alarm: ' + convert(nvarchar, @alarm)
--print str(@event_id)
update agro_fuel_level_alarm set is_checked = 1, is_alarm = @alarm where id = @event_id 

while @@FETCH_STATUS = 0
begin
	insert into agro_fuel_alarms_found_devices(alarm_id, device_id) values (@event_id, @did)
	
	fetch cursor_ into @did, @gid, @ddt
end

close cursor_

END
