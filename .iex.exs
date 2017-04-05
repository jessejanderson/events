alias Events.{Event, Room, Conflict}
alias Calendar.DateTime
alias Calendar.DateTime.Interval

timezone = "America/Los_Angeles"

{:ok, event} = Event.start_link("My Event")
{:ok, room1} = Room.start_link("Room 101")
{:ok, room2} = Room.start_link("Room 202")

date1 = {{2017, 5, 30}, {13, 0, 0}}
date2 = {{2017, 5, 30}, {15, 30, 0}}
datetime1 = DateTime.from_erl!({{2017, 5, 30}, {14, 0, 0}}, timezone)
datetime2 = DateTime.from_erl!({{2017, 5, 30}, {17, 0, 0}}, timezone)

interval = %Interval{from: datetime1, to: datetime2}

Event.add_rooms(event, [room1, room2])
Event.set_datetime_start(event, date1)
Event.set_datetime_end(event, date2)
