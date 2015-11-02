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

--  This package provides a specialization of the Element_Traits package for
--  use with indefinite type (i.e. their size might not be known at compile
--  time).
--  Such elements are returned as reference types, so containers will not
--  return the element itself. This is in general more efficient and safer,
--  and avoids copying potentially large elements.

pragma Ada_2012;

generic
   type Element_Type (<>) is private;

   with procedure Free (E : in out Element_Type) is null;
   --  This procedure is called when the element is removed from its
   --  container.

   with package Pool is new Conts.Pools (<>);

package Conts.Elements.Indefinite_Ref with SPARK_Mode is

   type Element_Access is access all Element_Type;
   for Element_Access'Storage_Pool use Pool.Pool.all;

   type Ref_Type (Element : not null access Element_Type) is null record
      with Implicit_Dereference => Element;
   --  ??? Would be nice if we could make this constrained by
   --  providing a default value for the discriminant, but this is
   --  illegal.

   function To_Element_Access (E : Element_Type) return Element_Access
      is (new Element_Type'(E)) with Inline;
   function To_Ref (E : Element_Access) return Ref_Type
      is (Ref_Type'(Element => E)) with Inline;
   function Copy (E : Element_Access) return Element_Access
      is (new Element_Type'(E.all)) with Inline;
   procedure Release (E : in out Element_Access) with Inline;

   package Traits is new Conts.Elements.Traits
      (Element_Type        => Element_Type,
       Stored_Type         => Element_Access,
       Return_Type         => Ref_Type,
       To_Stored           => To_Element_Access,
       To_Return           => To_Ref,
       Copy                => Copy,
       Release             => Release,
       Copyable            => False,   --  would create aliases
       Movable             => True);

   function From_Ref_To_Element (R : Ref_Type) return Element_Type
      is (R.Element.all) with Inline_Always;
   --  Convenience function for use in algorithms, to convert from a Ref_Type
   --  to an Element_Type. This is not needed in general, since the compiler
   --  will automatically (and efficiently) dereference the reference_type.
   --  But generic algorithm need an explicit conversion.

end Conts.Elements.Indefinite_Ref;
