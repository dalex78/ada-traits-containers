------------------------------------------------------------------------------
--                     Copyright (C) 2015, AdaCore                          --
--                                                                          --
-- This library is free software;  you can redistribute it and/or modify it --
-- under terms of the  GNU General Public License  as published by the Free --
-- Software  Foundation;  either version 3,  or (at your  option) any later --
-- version. This library is distributed in the hope that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE.                            --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
------------------------------------------------------------------------------

pragma Ada_2012;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Indefinite_Doubly_Linked_Lists;
with Ada.Calendar;       use Ada.Calendar;
with Conts.Lists.Definite_Unbounded;
with Conts.Lists.Indefinite_Unbounded;
with Conts.Lists.Indefinite_Unbounded_Ref;
with Conts.Lists.Indefinite_Unbounded_SPARK;
with Conts.Lists.Definite_Bounded;
with Conts.Lists.Definite_Bounded_Limited;
with Conts.Algorithms;
with Conts.Cursors.Adaptors;     use Conts.Cursors.Adaptors;
with Taggeds;
with Report;             use Report;

--  The tests all use a subprogram with a class-wide parameter, to force the
--  use of dynamic dispatching and simulate real applications.

package body Perf_Support is

   function Predicate (P : Integer) return Boolean is (P > 3)
      with Inline => True;

   function Starts_With_Str (S : String) return Boolean is
      (S (S'First) = 's');
   pragma Inline (Starts_With_Str);

   procedure Assert (Count, Expected : Natural) with Inline => True;

   ------------
   -- Assert --
   ------------

   procedure Assert (Count, Expected : Natural) is
   begin
      if Count /= Expected then
         raise Program_Error with "Wrong count: got"
            & Count'Img & " expected" & Expected'Img;
      end if;
   end Assert;

   -------------------------------
   -- Test_Lists_Int_Indefinite --
   -------------------------------

   procedure Test_Lists_Int_Indefinite (Stdout : in out Output'Class) is
      package Lists is new Conts.Lists.Indefinite_Unbounded
         (Element_Type   => Integer);
      use Lists;
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Lists.Cursors.Constant_Forward);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It : Lists.Cursor;
         Co : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count - 2 loop
                  V2.Append (2);
               end loop;
               V2.Append (5);
               V2.Append (6);

            when Column_Copy =>
               declare
                  V_Copy : Lists.List'Class := V2;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               It := V2.First;
               while V2.Has_Element (It) loop
                  if Predicate (V2.Element (It)) then
                     Co := Co + 1;
                  end if;
                  It := V2.Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_For_Of =>
               for E of V2 loop
                  if Predicate (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_Count_If =>
               Assert (Count_If (V2, Predicate'Access), 2);

            when others => null;
         end case;
      end Run;

      V : Lists.List;
   begin
      All_Tests (Stdout, "List iuc", V);
   end Test_Lists_Int_Indefinite;

   -------------------------------------
   -- Test_Lists_Int_Indefinite_SPARK --
   -------------------------------------

   procedure Test_Lists_Int_Indefinite_SPARK (Stdout : in out Output'Class) is
      package Lists is new Conts.Lists.Indefinite_Unbounded_SPARK
         (Element_Type   => Integer);
      use Lists;
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Lists.Cursors.Constant_Forward);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It : Lists.Cursor;
         Co : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count - 2 loop
                  V2.Append (2);
               end loop;
               V2.Append (5);
               V2.Append (6);

            when Column_Copy =>
               declare
                  --  Cannot use ":=" since the type is limited
                  V_Copy : Lists.List'Class := V2.Copy;
               begin
                  Stdout.Print_Time (Clock - Start);
                  V_Copy.Clear;   --  explicit deallocation is needed
               end;

            when Column_Loop =>
               It := V2.First;
               while V2.Has_Element (It) loop
                  if Predicate (V2.Element (It)) then
                     Co := Co + 1;
                  end if;
                  It := V2.Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_For_Of =>
               for E of V2 loop
                  if Predicate (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_Count_If =>
               Assert (Count_If (V2, Predicate'Access), 2);

            when others => null;
         end case;
      end Run;

      V : Lists.List;
   begin
      All_Tests (Stdout, "List isl", V);
      V.Clear;   --  explicit deallocation is needed
   end Test_Lists_Int_Indefinite_SPARK;

   --------------------
   -- Test_Lists_Int --
   --------------------

   procedure Test_Lists_Int (Stdout : in out Output'Class) is
      package Lists is new Conts.Lists.Definite_Unbounded
         (Element_Type   => Integer);
      use Lists, Lists.Lists;   --  second is for Ada95 notation
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Lists.Cursors.Constant_Forward);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It : Lists.Cursor;
         Co : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count - 2 loop
                  V2.Append (2);
               end loop;
               V2.Append (5);    --  testing withe prefix notation
               Append (V2, 6);   --  testing with Ada95 notation

            when Column_Copy =>
               declare
                  V_Copy : Lists.List'Class := V2;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               It := V2.First;
               while V2.Has_Element (It) loop
                  if Predicate (V2.Element (It)) then
                     Co := Co + 1;
                  end if;
                  It := V2.Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_For_Of =>
               for E of V2 loop
                  if Predicate (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_Count_If =>
               Assert (Count_If (V2, Predicate'Access), 2);

            when others => null;
         end case;
      end Run;

      V : Lists.List;
   begin
      All_Tests (Stdout, "List duc", V);
   end Test_Lists_Int;

   --------------------------------
   -- Test_Lists_Bounded_Limited --
   --------------------------------

   procedure Test_Lists_Bounded_Limited (Stdout : in out Output'Class) is
      package Lists is new Conts.Lists.Definite_Bounded_Limited
         (Element_Type   => Integer);
      use Lists;
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Lists.Cursors.Constant_Forward);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It : Lists.Cursor;
         Co : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Small_Items_Count - 2 loop
                  V2.Append (2);
               end loop;
               V2.Append (5);
               V2.Append (6);

            when Column_Copy =>
               declare
                  --  Cannot use ":=", the container is limited
                  V_Copy : Lists.List'Class := V2.Copy;
               begin
                  Stdout.Print_Time (Clock - Start);
                  V_Copy.Clear;  --  Type is not controlled
               end;

            when Column_Loop =>
               It := V2.First;
               while V2.Has_Element (It) loop
                  if Predicate (V2.Element (It)) then
                     Co := Co + 1;
                  end if;
                  It := V2.Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_For_Of =>
               for E of V2 loop
                  if Predicate (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start, "(1)");
               Assert (Co, 2);

            when Column_Count_If =>
               Assert (Count_If (V2, Predicate'Access), 2);

            when others => null;
         end case;
      end Run;

      V : Lists.List (Capacity => Small_Items_Count);
   begin
      All_Tests (Stdout, "List dbl", V, Fewer_Items => True);
      V.Clear;   --  Need explicit deallocation, this is limited
   end Test_Lists_Bounded_Limited;

   ------------------------
   -- Test_Lists_Bounded --
   ------------------------

   procedure Test_Lists_Bounded (Stdout : in out Output'Class) is
      package Lists is new Conts.Lists.Definite_Bounded
         (Element_Type   => Integer);
      use Lists;
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Lists.Cursors.Constant_Forward);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It : Lists.Cursor;
         Co : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Small_Items_Count - 2 loop
                  V2.Append (2);
               end loop;
               V2.Append (5);
               V2.Append (6);

            when Column_Copy =>
               declare
                  V_Copy : Lists.List'Class := V2;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               It := V2.First;
               while V2.Has_Element (It) loop
                  if Predicate (V2.Element (It)) then
                     Co := Co + 1;
                  end if;
                  It := V2.Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_For_Of =>
               for E of V2 loop
                  if Predicate (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start, "(1)");
               Assert (Co, 2);

            when Column_Count_If =>
               Assert (Count_If (V2, Predicate'Access), 2);

            when others => null;
         end case;
      end Run;

      V : Lists.List (Capacity => Small_Items_Count);
   begin
      All_Tests (Stdout, "List dbc", V, Fewer_Items => True);
      V.Clear;   --  Need explicit deallocation, this is limited
   end Test_Lists_Bounded;

   --------------------
   -- Test_Lists_Str --
   --------------------

   procedure Test_Lists_Str (Stdout : in out Output'Class) is
      package Lists is new Conts.Lists.Indefinite_Unbounded
         (Element_Type   => String);
      use Lists;
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Lists.Cursors.Constant_Forward);

      function Ref_Starts_With_Str (S : String) return Boolean
         is (S (S'First) = 's');
      pragma Inline (Ref_Starts_With_Str);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It    : Lists.Cursor;
         Co    : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count loop
                  V2.Append ("str1");
               end loop;

            when Column_Copy =>
               declare
                  V_Copy : Lists.List'Class := V2;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               It := V2.First;
               while V2.Has_Element (It) loop
                  if Ref_Starts_With_Str (V2.Element (It)) then
                     Co := Co + 1;
                  end if;
                  It := V2.Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, Items_Count);

            when Column_For_Of =>
               for E of V2 loop
                  if Starts_With_Str (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, Items_Count);

            when Column_Count_If =>
               Assert (Count_If (V2, Ref_Starts_With_Str'Access), Items_Count);

            when others => null;
         end case;
      end Run;

      V : Lists.List;
   begin
      All_Tests (Stdout, "List iuc", V);
   end Test_Lists_Str;

   ------------------------------
   -- Test_Lists_Str_Reference --
   ------------------------------

   procedure Test_Lists_Str_Reference (Stdout : in out Output'Class) is
      package Lists is new Conts.Lists.Indefinite_Unbounded_Ref
         (Element_Type   => String);
      use Lists;
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Lists.Cursors.Constant_Forward);

      function Ref_Starts_With_Str (S : Lists.Ref_Type) return Boolean
         is (S (S.E'First) = 's');
      pragma Inline (Ref_Starts_With_Str);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V2 : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It    : Lists.Cursor;
         Co    : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count loop
                  V2.Append ("str1");
               end loop;

            when Column_Copy =>
               declare
                  V_Copy : Lists.List'Class := V2;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               It := V2.First;
               while V2.Has_Element (It) loop
                  if Ref_Starts_With_Str (V2.Element (It)) then
                     Co := Co + 1;
                  end if;
                  It := V2.Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, Items_Count);

            when Column_For_Of =>
               for E of V2 loop
                  if Starts_With_Str (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, Items_Count);

            when Column_Count_If =>
               Assert (Count_If (V2, Ref_Starts_With_Str'Access), Items_Count);

            when others => null;
         end case;
      end Run;

      V : Lists.List;
   begin
      All_Tests (Stdout, "List iuc 4", V);
   end Test_Lists_Str_Reference;

   ----------------------
   -- Test_Ada2012_Str --
   ----------------------

   procedure Test_Ada2012_Str (Stdout : in out Output'Class) is
      package Lists is new Ada.Containers.Indefinite_Doubly_Linked_Lists
         (String);
      use Lists;
      package Adaptors is new Indefinite_List_Adaptors (Lists);
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Adaptors.Cursors.Forward);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It    : Lists.Cursor;
         Co    : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count loop
                  V.Append ("str1");
               end loop;

            when Column_Copy =>
               declare
                  V_Copy : constant Lists.List'Class  := V;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               It := V.First;
               while Has_Element (It) loop
                  if Starts_With_Str (Element (It)) then  --  secondary stack
                     Co := Co + 1;
                  end if;
                  Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, Items_Count);

            when Column_For_Of =>
               for E of V loop
                  if Starts_With_Str (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, Items_Count);

            when Column_Count_If =>
               Assert (Count_If (V, Starts_With_Str'Access), Items_Count);

            when others => null;
         end case;
      end Run;

      V  : Lists.List;
   begin
      All_Tests (Stdout, "Ada iu", V);
   end Test_Ada2012_Str;

   --------------------------------
   -- Test_Ada2012_Str_No_Checks --
   --------------------------------

   procedure Test_Ada2012_Str_No_Checks (Stdout : in out Output'Class) is
      pragma Suppress (Container_Checks);
      package Lists is new Ada.Containers.Indefinite_Doubly_Linked_Lists
         (String);
      use Lists;
      package Adaptors is new Indefinite_List_Adaptors (Lists);
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Adaptors.Cursors.Forward);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It    : Lists.Cursor;
         Co    : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count loop
                  V.Append ("str1");
               end loop;

            when Column_Copy =>
               declare
                  V_Copy : constant Lists.List'Class  := V;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               It := V.First;
               while Has_Element (It) loop
                  if Starts_With_Str (Element (It)) then  --  secondary stack
                     Co := Co + 1;
                  end if;
                  Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, Items_Count);

            when Column_For_Of =>
               for E of V loop
                  if Starts_With_Str (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, Items_Count);

            when Column_Count_If =>
               Assert (Count_If (V, Starts_With_Str'Access), Items_Count);

            when others => null;
         end case;
      end Run;

      V  : Lists.List;
   begin
      All_Tests (Stdout, "Ada iu no", V);
   end Test_Ada2012_Str_No_Checks;

   ---------------------
   -- Test_Arrays_Int --
   ---------------------

   procedure Test_Arrays_Int (Stdout : in out Output'Class) is
      type Int_Array is array (Integer range <>) of Integer;
      package Adaptors is new Array_Adaptors
         (Index_Type   => Integer,
          Element_Type => Integer,
          Array_Type   => Int_Array);
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Adaptors.Cursors.Forward);

      procedure Run (V : in out Int_Array; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Int_Array);

      procedure Run
         (V : in out Int_Array; Col : Column_Number; Start : Time)
      is
         Co : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Small_Items_Count - 2 loop
                  V (C) := 2;
               end loop;
               V (V'Last - 1) := 5;
               V (V'Last) := 6;

            when Column_Copy =>
               declare
                  V_Copy : Int_Array := V;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               for It in V'Range loop
                  if Predicate (V (It)) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_For_Of =>
               for E of V loop
                  if Predicate (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_Count_If =>
               Assert (Count_If (V, Predicate'Access), 2);

            when others => null;
         end case;
      end Run;

      V     : Int_Array (1 .. Small_Items_Count);
   begin
      All_Tests (Stdout, "Array", V, Fewer_Items => True);
   end Test_Arrays_Int;

   ----------------------
   -- Test_Ada2012_Int --
   ----------------------

   procedure Test_Ada2012_Int (Stdout : in out Output'Class) is
      package Lists is new Ada.Containers.Doubly_Linked_Lists (Integer);
      use Lists;
      package Adaptors is new List_Adaptors (Lists);
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Adaptors.Cursors.Forward);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It    : Lists.Cursor;
         Co    : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count - 2 loop
                  V.Append (2);
               end loop;
               V.Append (5);
               V.Append (6);

            when Column_Copy =>
               declare
                  V_Copy : constant Lists.List'Class := V;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               It := V.First;
               while Has_Element (It) loop
                  if Predicate (Element (It)) then
                     Co := Co + 1;
                  end if;
                  Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_For_Of =>
               for E of V loop
                  if Predicate (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_Count_If =>
               Assert (Count_If (V, Predicate'Access), 2);

            when others => null;
         end case;
      end Run;

      V  : Lists.List;
   begin
      All_Tests (Stdout, "Ada du", V);
   end Test_Ada2012_Int;

   --------------------------------
   -- Test_Ada2012_Int_No_Checks --
   --------------------------------

   procedure Test_Ada2012_Int_No_Checks (Stdout : in out Output'Class) is
      pragma Suppress (Container_Checks);
      package Lists is new Ada.Containers.Doubly_Linked_Lists (Integer);
      use Lists;
      package Adaptors is new List_Adaptors (Lists);
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Adaptors.Cursors.Forward);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It    : Lists.Cursor;
         Co    : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count - 2 loop
                  V.Append (2);
               end loop;
               V.Append (5);
               V.Append (6);

            when Column_Copy =>
               declare
                  V_Copy : constant Lists.List'Class := V;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               It := V.First;
               while Has_Element (It) loop
                  if Predicate (Element (It)) then
                     Co := Co + 1;
                  end if;
                  Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_For_Of =>
               for E of V loop
                  if Predicate (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_Count_If =>
               Assert (Count_If (V, Predicate'Access), 2);

            when others => null;
         end case;
      end Run;

      V  : Lists.List;
   begin
      All_Tests (Stdout, "Ada du no", V);
   end Test_Ada2012_Int_No_Checks;

   ---------------------------------
   -- Test_Ada2012_Int_Indefinite --
   ---------------------------------

   procedure Test_Ada2012_Int_Indefinite (Stdout : in out Output'Class) is
      package Lists is new Ada.Containers.Indefinite_Doubly_Linked_Lists
         (Integer);
      use Lists;
      package Adaptors is new Indefinite_List_Adaptors (Lists);
      function Count_If is new Conts.Algorithms.Count_If
         (Cursors => Adaptors.Cursors.Forward);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         It    : Lists.Cursor;
         Co    : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count - 2 loop
                  V.Append (2);
               end loop;
               V.Append (5);
               V.Append (6);

            when Column_Copy =>
               declare
                  V_Copy : constant Lists.List'Class := V;
                  pragma Unreferenced (V_Copy);
               begin
                  Stdout.Print_Time (Clock - Start);
               end;

            when Column_Loop =>
               It := V.First;
               while Has_Element (It) loop
                  if Predicate (Element (It)) then
                     Co := Co + 1;
                  end if;
                  Next (It);
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_For_Of =>
               for E of V loop
                  if Predicate (E) then
                     Co := Co + 1;
                  end if;
               end loop;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when Column_Count_If =>
               Assert (Count_If (V, Predicate'Access), 2);

            when others => null;
         end case;
      end Run;

      V  : Lists.List;
   begin
      All_Tests (Stdout, "Ada iu", V);
   end Test_Ada2012_Int_Indefinite;

   ---------------------
   -- Test_Tagged_Int --
   ---------------------

   procedure Test_Tagged_Int (Stdout : in out Output'Class) is
      package Lists is new Taggeds (Integer);
      use Lists;

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time);
      procedure All_Tests is new Run_Tests (Lists.List'Class);

      procedure Run
         (V : in out Lists.List'Class; Col : Column_Number; Start : Time)
      is
         Co    : Natural := 0;
      begin
         case Col is
            when Column_Fill =>
               for C in 1 .. Items_Count - 2 loop
                  V.Append (2);
               end loop;
               V.Append (5);
               V.Append (6);

            when Column_Loop =>
               declare
                  It  : Lists.List_Cursor'Class := List_Cursor (V.First);
                  --  Casting to List_Cursor here halves the time to run the
                  --  loop by avoiding dynamic dispatching.
               begin
                  while It.Has_Element loop
                     if Predicate (It.Element) then
                        Co := Co + 1;
                     end if;
                     It.Next;
                  end loop;
               end;
               Stdout.Print_Time (Clock - Start);
               Assert (Co, 2);

            when others =>
               Stdout.Print_Not_Run;  --  copy
         end case;
      end Run;

      V : Lists.List;
   begin
      All_Tests (Stdout, "Tagged", V);
   end Test_Tagged_Int;

end Perf_Support;