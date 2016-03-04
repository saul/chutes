with Ada.Calendar; use Ada.Calendar;

package Oh_Chute is
  type Ball_Sensed is (Metal, Unknown);

  -- load hopper
  procedure Hopper_Load;

  -- unload hopper
  procedure Hopper_Unload;

  -- first solenoid open & second closed
  procedure Sorter_Metal;

  -- second solenoid open & first closed
  procedure Sorter_Glass;

  -- neither solenoid open
  procedure Sorter_Close;

  -- returns ball type and time detected,
  -- blocks the calling task until a ball is detected
  procedure Get_Next_Sensed_Ball(B: out Ball_Sensed; T: out Time);
end Oh_Chute;
