pragma Ada_2012;
with Ada.Unchecked_Deallocation;

package Conts is

   subtype Count_Type is Natural;

   --------------
   -- Elements --
   --------------
   --  This package describes the types of elements stored in a container.
   --  We want to handle both constrained and unconstrained elements, which is
   --  done by providing subprograms to convert from one type to the other
   --  (presumably, but not limited to, using access types)

   generic
      type Element_Type (<>) is private;
      --  The element type visible to the user (in parameter to Append, and
      --  returned by Element, for instance)

      type Stored_Element_Type is private;
      --  The type of elements stored internally. This must be unconstrained.

      type Reference_Type (<>) is private;
      --  A safer way to access Stored_Element_Type. The intent is that for
      --  indefinite element this will be a record with an access discriminant
      --  and automatic dereferencing. This is safer (user can't free the
      --  pointer, but also slower since this is an unconstrained type and
      --  thus more costly to return from a function)

      with function Convert_From (E : Element_Type) return Stored_Element_Type;
      with function Convert_To (E : Stored_Element_Type) return Element_Type;
      with function Get_Reference
         (E : Stored_Element_Type) return Reference_Type;
      --  Converting between the two types

      with procedure Release (E : in out Stored_Element_Type) is null;
      --  Called whenever a value of Element_Type is removed from the table.
      --  This can be used to add unconstrained types to the list: Element_Type
      --  would then be a pointer to that type, and Release is a call to
      --  Unchecked_Deallocation.

   package Elements_Traits is
      --  pragma Unreferenced (Convert_From, Convert_To, Release);
      --  Can't use the pragma above since other packages need those. But then
      --  the compiler is complaining that these formal parameters are unused
   end Elements_Traits;

   -------------------------------------
   -- Definite (constrained) elements --
   -------------------------------------

   generic
      type Element_Type is private;
   package Definite_Elements_Traits is
      function Identity (E : Element_Type) return Element_Type is (E);
      pragma Inline (Identity);
      package Elements is new Elements_Traits
         (Element_Type        => Element_Type,
          Stored_Element_Type => Element_Type,
          Reference_Type      => Element_Type,
          Get_Reference       => Identity,
          Convert_From        => Identity,
          Convert_To          => Identity);
   end Definite_Elements_Traits;

   -----------------------------------------
   -- Indefinite (unconstrained) elements --
   -----------------------------------------

   generic
      type Element_Type (<>) is private;
   package Indefinite_Elements_Traits is
      type Element_Access is access all Element_Type;

      type Reference_Type (E : null access Element_Type) is null record
         with Implicit_Dereference => E;
      --  ??? Would be nice if we could make this constrained by
      --  providing a default value for the discriminant, but this is
      --  illegal.

      procedure Unchecked_Free is new Ada.Unchecked_Deallocation
         (Element_Type, Element_Access);
      function To_Element_Access (E : Element_Type) return Element_Access
         is (new Element_Type'(E));
      function To_Element_Type (E : Element_Access) return Element_Type
         is (E.all);
      function Get_Reference (E : Element_Access) return Reference_Type
         is (Reference_Type'(E => E));
      pragma Inline (To_Element_Access, To_Element_Type, Get_Reference);

      package Elements is new Elements_Traits
         (Element_Type        => Element_Type,
          Stored_Element_Type => Element_Access,
          Convert_From        => To_Element_Access,
          Convert_To          => To_Element_Type,
          Reference_Type      => Reference_Type,
          Get_Reference       => Get_Reference,
          Release             => Unchecked_Free);
   end Indefinite_Elements_Traits;

   -------------
   -- Cursors --
   -------------

   generic
      type Container (<>) is limited private;
      type Cursor is private;
      type Element_Type (<>) is private;
      with function First (Self : Container) return Cursor is <>;
      with function Element (Self : Container; Position : Cursor)
         return Element_Type is <>;
      with function Has_Element (Self : Container; Position : Cursor)
         return Boolean is <>;
      with function Next (Self : Container; Position : Cursor)
         return Cursor is <>;
   package Forward_Cursors_Traits is
   end Forward_Cursors_Traits;
   --  A package that describes how to use forward cursors.
   --  Each contain for which this is applicable provides an instance of
   --  this package, and algorithms should take this package as a
   --  generic parameter.

   generic
      type Container (<>) is limited private;
      type Cursor is private;
      type Element_Type (<>) is private;
      with function First (Self : Container) return Cursor is <>;
      with function Element (Self : Container; Position : Cursor)
         return Element_Type is <>;
      with function Has_Element (Self : Container; Position : Cursor)
         return Boolean is <>;
      with function Next (Self : Container; Position : Cursor)
         return Cursor is <>;
      with function Previous (Self : Container; Position : Cursor)
         return Cursor is <>;
   package Bidirectional_Cursors_Traits is

      --  A bidirectional cursor is also a forward cursor
      package Forward_Cursors is new Forward_Cursors_Traits
         (Container, Cursor, Element_Type);
   end Bidirectional_Cursors_Traits;

end Conts;
