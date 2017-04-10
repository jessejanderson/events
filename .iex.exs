# alias Events.{Conflict, Event, EventList, Room, RoomList}
# alias Calendar.DateTime.Interval
# alias Calendar.DateTime

# timezone = "America/Los_Angeles"

# IO.puts "##### Create a new event with 2 rooms"

# {:ok, room1} = Room.new("Room 101")
# {:ok, room2} = Room.new("Room 202")

# {:ok, event1} = Event.new(1, "My First Event")
# {:ok, event2} = Event.new(1, "My Second Event")

# date1 = {{2017, 5, 30}, {13, 0, 0}}
# date2 = {{2017, 5, 30}, {16, 0, 0}}
# date3 = {{2017, 5, 30}, {15, 0, 0}}
# date4 = {{2017, 5, 30}, {18, 0, 0}}

# Event.set_interval(event1, date1, date2)
# Event.set_interval(event2, date3, date4)

# datetime1 = DateTime.from_erl!({{2017, 5, 30}, {14, 0, 0}}, timezone)
# datetime2 = DateTime.from_erl!({{2017, 5, 30}, {17, 0, 0}}, timezone)

# interval = %Interval{from: datetime1, to: datetime2}

# Event.add_room(event1, room1)
# Event.add_room(event1, room2)
