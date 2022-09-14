class fifo_sb;
  // mailbox fifo = new();
   bit [7:0]  fifo_queue [$:31]; //si ponemos  tamanyo 32 los procedimientos del 2013 fallan
   integer size;
   virtual fifo_if.monitor mports2;

   function new(virtual fifo_if.monitor mports3);
   begin
     size = 0;
     mports2=mports3;
   end  
   endfunction

   task addItem_2013(bit [7:0] data);//este funciona con tamanyo 33 en la cola
   begin
     if (size == 32) begin
       $write("%dns : ERROR : Over flow detected, current occupancy %d\n",
         $time, size);
          fifo_queue.push_back(data);
         size ++;
     end else begin
       fifo_queue.push_back(data);
       size ++;
     end
   end
   endtask
   
   task addItem(bit [7:0] data);
   begin
    fork
      begin
          wait (fifo_queue.size()<32);
          fifo_queue.push_back(data);
          size=fifo_queue.size();
      end
              @ (mports2.px)  #0        $write("%dns : ERROR : Over flow detected, current occupancy %d\n", $time, fifo_queue.size());
    
    join_any
    disable fork;
   end
   endtask
   

   task compareItem (bit [7:0] data);
   begin
     bit [7:0] cdata  = 0;
     fork
      begin
        wait (fifo_queue.size()>0)
        cdata=fifo_queue.pop_front;
        size=fifo_queue.size();
        a_check0: assert (data == cdata) else
          $error("%dns : ERROR : Data mismatch, Expected %x Got %x\n",$time, cdata, data );
      end
     #0      $write("%dns : ERROR : Under flow detected,current occupancy %d\n", $time, fifo_queue.size()); //esta rrama del no debería saltar nunca
    join_any
    disable fork;     
   end
   endtask
   
   task compareItem_2013 (bit [7:0] data);//este funciona con tamanyo 33 en la cola
   begin
     bit [7:0] cdata  = 0;
     if (size == 0) begin
       $write("%dns : ERROR : Under flow detected\n", $time);
       cdata=fifo_queue.pop_front;
       a_check0: assert (data == cdata) else
         $error("%dns : ERROR : Data mismatch, Expected %x Got %x\n", 
         $time, cdata, data );
       
     end else begin
       cdata=fifo_queue.pop_front;
       a_check1: assert (data == cdata) else
         $error("%dns : ERROR : Data mismatch, Expected %x Got %x\n", 
           $time, cdata, data );
       
       size --;
     end
   end
   endtask 
  task vaciar ();
   begin
    fifo_queue={};
   end
 endtask
endclass
