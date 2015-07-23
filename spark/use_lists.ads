pragma Ada_2012;
with Formal_Doubly_Linked_Lists;
pragma Elaborate_All (Formal_Doubly_Linked_Lists);

package Use_Lists with SPARK_Mode is
   package My_Lists is new Formal_Doubly_Linked_Lists
     (Element_Type => Integer,
      "="          => "=");
   use My_Lists;
   use My_Lists.Model;
   use type My_Lists.Cursor;
   use My_Lists.Model.Cursor_Map;
   use My_Lists.Model.Element_Sequence;

   function Is_Incr (I1, I2 : Integer) return Boolean is
      (if I1 = Integer'Last then I2 = Integer'Last else I2 = I1 + 1);

   procedure Incr_All (L1 : List; L2 : in out List) with
     Pre  => Capacity (L2) >= Capacity (L1),
     Post => Capacity (L2) = Capacity (L2)'Old
     and Length (L2) = Length (L1)
     and (for all N in 1 .. Length (L1) =>
              Is_Incr (Get (Get_Model (L1), N),
                       Get (Get_Model (L2), N)));

   procedure Incr_All_2 (L : in out List) with
     Post => Capacity (L) = Capacity (L)'Old
     and Length (L) = Length (L)'Old
     and (for all N in 1 .. Length (L) =>
              Is_Incr (Get (Get_Model (L)'Old, N),
                       Get (Get_Model (L), N)));

   procedure Incr_All_3 (L : in out List) with
     Post => Capacity (L) = Capacity (L)'Old
     and Length (L) = Length (L)'Old
     and (for all N in 1 .. Length (L) =>
              Is_Incr (Get (Get_Model (L)'Old, N),
                       Get (Get_Model (L), N)))
     and Inc (Get_Positions (L)'Old, Get_Positions (L))
     and Inc (Get_Positions (L), Get_Positions (L)'Old);

   procedure Double_Size (L : in out List) with
     Pre  => Capacity (L) / 2 >= Length (L),
     Post => Capacity (L) = Capacity (L)'Old
     and Length (L) = 2 * Length (L)'Old
     and (for all I in 1 .. Length (L)'Old =>
       Get (Get_Model (L), I) = Get (Get_Model (L)'Old, I)
       and Get (Get_Model (L), I + Length (L)'Old) =
           Get (Get_Model (L)'Old, I));

   procedure Double_Size_2 (L : in out List) with
     Pre  => Capacity (L) / 2 >= Length (L),
     Post => Capacity (L) = Capacity (L)'Old
     and Length (L) = 2 * Length (L)'Old
     and (for all I in 1 .. Length (L)'Old =>
       Get (Get_Model (L), 2 * I - 1) = Get (Get_Model (L)'Old, I)
       and Get (Get_Model (L), 2 * I) =
           Get (Get_Model (L)'Old, I));

   function My_Find (L : List; E : Integer) return Cursor with
     Post => My_Find'Result = Find (L, E);
end Use_Lists;
