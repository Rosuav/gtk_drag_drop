constant DESCRIPTION = "Drag and Drop Between 2 Treeviews - by Vikram Ambrose";

/* Some sample data for treeview 1. A NULL row is added so we dont 
   need to pass around the size of the array */
array row_data = ({
	({ "row0","item 12", 3, 4.3 }),
	({ "row1","item 23", 44,34.4}),
	({ "row2","item 33", 34,25.4}),
	({ "row3","item 43", 37,64.4}),
	({ "row4","item 53", 12,14.4}),
	({ "row5","item 68", 42,34.4}),
	({ "row6","item 75", 72,74.4}),
});

/* Sample data for treeview 2 */
array row2_data = ({
	({"row7", "item 127", 105, 115.5}),
	({"row8","item 124", 117, 118.6}),
	({"row9", "item 123", 120, 121.73}),
});

constant drag_targets = ({
	({"text/plain", GTK2.TARGET_SAME_APP, 0}),
});

/* Convenience function to print out the contents of a DATA struct onto stdout */
void print_DATA(array data){
	write("DATA @ %x\n", hash_value(data));
	write(" |->row = %s\n",data[0]);
	write(" |->item = %s\n",data[1]);
	write(" |->qty = %d\n",data[2]);
	write(" +->price = %f\n",data[3]);
}

/* User callback for "get"ing the data out of the row that was DnD'd */
mixed on_drag_data_get(GTK2.Widget self, GDK2.DragContext drag_context,
			GTK2.SelectionData sdata, int info, int time) {
	write("on_drag_data_get: self %O, dc %O, sd %O\n", self, drag_context, sdata);

	/* Get the selector widget from the treeview in question */
	/* Get the tree model (list_store) and initialise the iterator */
	[GTK2.TreeIter iter, GTK2.TreeModel list_store] = self->get_selection()->get_selected();
	array temp = list_store->get_row(iter);
	sdata->set_text(Standards.JSON.encode(temp));
	print_DATA(temp);
}

/* User callback for putting the data into the other treeview */
void on_drag_data_received(GTK2.Widget self, GDK2.DragContext drag_context,
			int x, int y, GTK2.SelectionData sdata, int info,
			int time) {
	write("on_drag_data_received:\n");

	//Variation from the C version: ask what the source widget is, don't hard-code it!
	GTK2.Widget source = drag_context->get_source_widget();

	/* Remove row from the source treeview */
	[GTK2.TreeIter iter, GTK2.TreeModel list_store] = source->get_selection()->get_selected();
	list_store->remove(iter);

	/* Now add to the other treeview */
	GTK2.TreeModel list_store2 = self->get_model();
	GTK2.TreeIter iter2 = list_store2->append();

	/* Copy the pointer we received into a new struct */
	array temp = Standards.JSON.decode(sdata->get_text());

	/* Add the received data to the treeview model */
	list_store2->set_row(iter2, temp);
}

/* User callback just to see which row was selected, doesnt affect DnD. 
   However it might be important to note that this signal and drag-data-received may occur at the same time. If you drag a row out of one view, your selection changes too */
void on_selection_changed(object self) {
	[GTK2.TreeIter iter, GTK2.TreeModel list_store] = self->get_selected();
	/* "changed" signal sometimes fires blanks, so make sure we actually 
	 have a selection/
http://library.gnome.org/devel/gtk/stable/GtkTreeSelection.html#GtkTreeSelection-changed */
	if (!iter) {
		write("No row selected\n");
		return;
	}
	write("on_selection_changed: ");
	print_DATA(list_store->get_row(iter));
}

/* Create and populate a treeview */
GTK2.TreeView create_treeview(array data) {
	/* Create the treeview and its list store */
	GTK2.ListStore list_store = GTK2.ListStore(
		({"string", "string", "int", "float"}));

	GTK2.Widget tree_view = GTK2.TreeView(list_store);

	/* Add the columns */
	foreach (({"Row #", "Description", "Qty", "Price"}); int i; string hdr) {
		tree_view->append_column(GTK2.TreeViewColumn(hdr,
			GTK2.CellRendererText(), "text", i)
			->set_sort_column_id(i)
		);
	}

	/* Tell the theme engine we would like differentiated row colour */
	tree_view->set_rules_hint(1);

	/* Add the data */
	foreach (data, array row) {
		list_store->set_row(list_store->append(), row);
	}
	
	/* Attach the "changed" callback onto the tree's selector */
	tree_view->get_selection()->signal_connect("changed", on_selection_changed);
	return tree_view;
}

int main(int argc, array(string) argv){
	GTK2.setup_gtk(argv);

	/* Create the top level window and setup the quit callback */
	GTK2.TreeView view1, view2;
	GTK2.Window window = GTK2.Window(GTK.WINDOW_TOPLEVEL)
		->add(GTK2.Vbox(0, 10)
			->pack_start(GTK2.Label(DESCRIPTION), 0, 0, 1)
			->pack_start(GTK2.Hbox(1, 1)
				->pack_start(GTK2.ScrolledWindow()->set_policy(GTK2.POLICY_AUTOMATIC, GTK2.POLICY_AUTOMATIC)
					->add(view1 = create_treeview(row_data))
				, 1, 1, 2)
				->pack_start(GTK2.ScrolledWindow()->set_policy(GTK2.POLICY_AUTOMATIC, GTK2.POLICY_AUTOMATIC)
					->add(view2 = create_treeview(row2_data))
				, 1, 1, 2)
			, 1, 1, 1)
		)
		->set_default_size(666,266)->show_all();
	window->signal_connect("destroy", lambda() {exit(0);});

	view1->drag_source_set(GTK2.GDK_BUTTON1_MASK, drag_targets,
		GTK2.GDK_ACTION_COPY|GTK2.GDK_ACTION_MOVE);
	view1->signal_connect("drag-data-get", on_drag_data_get);

	/* Set treeview 2 as the destination of the Drag-N-Drop operation */
	view2->drag_dest_set(GTK2.DEST_DEFAULT_ALL,drag_targets,
		GTK2.GDK_ACTION_COPY|GTK2.GDK_ACTION_MOVE); 
	/* Attach a "drag-data-received" signal to pull in the dragged data */
	view2->signal_connect("drag-data-received", on_drag_data_received);

	/* Rock'n Roll */
	return -1;
}
