with Ada;
with Text_IO;
with Calendar; use Calendar;
with Ada.Exceptions; use Ada.Exceptions;
with MaRTE_OS;
with Oh_Chute; use Oh_Chute;
with Chute; use type Chute.Ball_Sensed;

procedure Main is

  function To_String(I : Integer) return String is
  begin
     return Integer'Image(I);
  end To_String;

  procedure Log_Exception(X : Exception_Occurrence) is
  begin
    Text_IO.Put_Line(" !!! EXCEPTION !!! EXCEPTION !!! EXCEPTION !!!");
    Text_IO.Put_Line(Exception_Information(X));
    Reraise_Occurrence(X);
  end Log_Exception;

  ---- synchronising when completed
  protected FinSync is
    entry WaitForCompletion;
    procedure Completed;
  private
    IsCompleted : Boolean := false;
  end FinSync;

  protected body FinSync is
    entry WaitForCompletion when IsCompleted is
    begin
      null;
    end WaitForCompletion;

    procedure Completed is
    begin
      IsCompleted := true;
    end Completed;
  end FinSync;

  ---- bounded buffer of balls in transit
  BufferSize : constant := 25;

  type BallArray is Array (1..BufferSize) of Chute.Ball_Sensed;

  protected BallBuffer is
    entry Put;
    entry Get(B : out Chute.Ball_Sensed);
    procedure ClassifyLastAs(B : Chute.Ball_Sensed);
  private
    Buffer : BallArray;
    Last_Put : integer range 0..BufferSize := 0;
    Next_out : integer range 1..BufferSize := 1;
    Curr_sz : integer range 0..BufferSize := 0;
  end BallBuffer;

  protected body BallBuffer is

    entry Put when curr_sz < BufferSize is
    begin
      Last_Put := Last_Put + 1;
      Buffer(Last_Put) := Chute.Unknown;
      Curr_sz := curr_sz + 1;
    end Put;

    entry Get(B : out Chute.Ball_Sensed) when curr_sz > 0 is
    begin
      B := Buffer(Next_out);
      Next_out := (Next_out mod BufferSize) + 1;
      Curr_sz := Curr_sz - 1;
    end Get;

    procedure ClassifyLastAs(B : Chute.Ball_Sensed) is
    begin
      Buffer(Last_Put) := B;
    end ClassifyLastAs;

  end BallBuffer;

  ---- ball releaser
  task BallReleaser;
  task body BallReleaser is
  begin

    select
      FinSync.WaitForCompletion;
    then abort
      loop
        Hopper_Load;
        delay 0.35;
        Hopper_Unload;

        BallBuffer.Put;
        delay 0.65; -- ball in transit
      end loop;
    end select;

  exception
    when E: others => Log_Exception(E);
  end BallReleaser;

  ---- ball detector
  task BallDetector;
  task body BallDetector is
    TotalMetal : Integer := 0;
    TotalGlass : Integer := 0;
    Sensed : Chute.Ball_Sensed;
    Last_Ball : Chute.Ball_Sensed;
    T : Time;
  begin

    loop
      select
        delay Duration(5);
        exit;
      then abort
        Get_Next_Sensed_Ball(Sensed, T);
      end select;

      Text_IO.Put_Line("Sensed ball " & Chute.Ball_Sensed'Image(Sensed));

      if Sensed = Chute.Metal then
        BallBuffer.ClassifyLastAs(Chute.Metal);
      elsif Sensed = Chute.Unknown then
        BallBuffer.Get(Last_Ball);

        if Last_Ball = Chute.Metal then
          TotalMetal := TotalMetal + 1;
          Sorter_Metal;
        else
          TotalGlass := TotalGlass + 1;
          Sorter_Glass;
        end if;
      end if;
    end loop;

    Text_IO.Put_Line("Completed sorting: " & To_String(TotalMetal) & " metal, " & To_String(TotalGlass) & " glass.");
    FinSync.Completed;

  exception
    when E: others => Log_Exception(E);
  end BallDetector;

begin
  Text_IO.Put_Line("I'm ready for your balls - v2");
end Main;
