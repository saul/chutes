package My_Little_Register_Control is
  type Hopper_Command is (Unload, Load);
  type Sorter_Command is (Open, Closed);

  procedure Initialize_Interfaces;
  procedure Write_Hopper_Command_Bits(Command : Hopper_Command);
  procedure Write_Sorter_Command_Bits(First : Sorter_Command; Second : Sorter_Command);

  procedure Wait_For_Software_Control;
private
  -- rep specs for types
end My_Little_Register_Control;
