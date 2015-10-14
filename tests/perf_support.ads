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
with Report;        use Report;
with System;

package Perf_Support is

   Column_Title    : constant Column_Number := 1;
   Column_Fill     : constant Column_Number := 2;
   Column_Copy     : constant Column_Number := 3;
   Column_Loop     : constant Column_Number := 4;
   Column_For_Of   : constant Column_Number := 5;
   Column_Count_If : constant Column_Number := 6;
   Column_Allocate : constant Column_Number := 7;
   Column_Allocs   : constant Column_Number := 8;
   Column_Reallocs : constant Column_Number := 9;
   Column_Frees    : constant Column_Number := 10;

   --  Performance testing when using generics, virtual methods and
   --  access to subprograms.

   --------------------
   -- Unary functors --
   --------------------
   --  These packages provide objects that act like functions, except it is
   --  possible to store data in them. They can thus be used to write
   --  accumulators, or to curry binary functions into unary functions.

   generic
      type Param is private;
      type Ret is private;
   package Unary_Functors is
      --  Define the types so that we can access the generic formals from an
      --  instance of this package.
      subtype Param_Type is Param;
      subtype Return_Type is Ret;

      type Obj is interface;
      function Call (Self : Obj; P : Param) return Ret is abstract;
   end Unary_Functors;

   generic
      with package F is new Unary_Functors (others => <>);
      with function Call (P : F.Param_Type) return F.Return_Type;
   package Unary_Functions is
      package Functors renames F;

      type Obj is new F.Obj with null record;
      overriding function Call
         (Self : Obj; P : F.Param_Type) return F.Return_Type
         is (Call (P));

      Make : constant Obj := (null record);
   end Unary_Functions;

   --------------------
   -- Using generics --
   --------------------

   generic
      type Param1 is private;
      type Param2 is private;
      type Ret is private;
      with function Call (P : Param1; Q : Param2) return Ret;
   package Binary_Functions is
      --  Define the types so that we can access the generic formals from an
      --  instance of this package.
      subtype Param1_Type is Param1;
      subtype Param2_Type is Param2;
      subtype Return_Type is Ret;
   end Binary_Functions;

   generic
      type Param1 is private;
      type Param2 is private;
      B : Param2;
      type Ret is private;
      with function Call (P : Param1; Q : Param2) return Ret;
   package Binder2nd is
      --  Define the types so that we can access the generic formals from an
      --  instance of this package.
      subtype Param1_Type is Param1;
      subtype Param2_Type is Param2;
      subtype Return_Type is Ret;

      function Binder_Call (P : Param1_Type) return Return_Type
         is (Call (P, B));
      --  package Funcs is new Unary_Functors
      --     (Param => Param1_Type,
      --      Ret   => Return_Type,
      --      Call  => Binder_Call);
   end Binder2nd;
   --  ??? Not the same as in C++ STL: since we do not have a class, there is
   --  no constructor to pass the value of the constant, which is therefore
   --  part of the generic formals, so we need a different instantiation for
   --  every possible value we might want for B.

   -----------
   -- Tests --
   -----------

   Items_Count : constant Integer := 300_000;
   pragma Export (C, Items_Count, "items_count");
   --  For some reason, using 600_000 results in a storage error when
   --  allocating the bounded limited containers.

   Small_Items_Count : constant Integer := Items_Count;
   --  In some cases, we can't allocate as many items as Items_Count (when
   --  using Ada arrays). In such cases, we use a smaller number of items.

   procedure Test_Lists_Int (Stdout : in out Output'Class);
   procedure Test_Lists_Int_Indefinite (Stdout : in out Output'Class);
   procedure Test_Lists_Int_Indefinite_SPARK (Stdout : in out Output'Class);
   procedure Test_Lists_Str (Stdout : in out Output'Class);
   procedure Test_Lists_Str_Reference (Stdout : in out Output'Class);
   procedure Test_Lists_Bounded (Stdout : in out Output'Class);
   procedure Test_Lists_Bounded_Limited (Stdout : in out Output'Class);
   --  Perform the tests for our own Conts containers

   procedure Test_Cpp_Int (Stdout : System.Address);
   pragma Import (C, Test_Cpp_Int, "test_c_int");
   procedure Test_Cpp_Str (Stdout : System.Address);
   pragma Import (C, Test_Cpp_Str, "test_c_str");
   --  Perform C++ testing

   procedure Test_Ada2012_Int (Stdout : in out Output'Class);
   procedure Test_Ada2012_Int_No_Checks (Stdout : in out Output'Class);
   procedure Test_Ada2012_Int_Indefinite (Stdout : in out Output'Class);
   procedure Test_Ada2012_Str (Stdout : in out Output'Class);
   procedure Test_Ada2012_Str_No_Checks (Stdout : in out Output'Class);
   --  Test Ada2012 containers

   procedure Test_Arrays_Int (Stdout : in out Output'Class);
   --  Test standard Ada arrays

   procedure Test_Tagged_Int (Stdout : in out Output'Class);
   --  Test when the list is implemented as tagged types

end Perf_Support;