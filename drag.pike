constant DESCRIPTION = "Drag and Drop Between 2 Treeviews - by Vikram Ambrose";
#if 0
/* Row data structure */
struct DATA { 
	char *row;
	char *item;
	int qty;
	float price;
};

/* A convenience enumerator to tag data types */
enum {
	TARGET_STRING,
	TARGET_INTEGER,
	TARGET_FLOAT
};
	
/* A convenience enumerator to count the columns */
enum {
	ROW_COL=0,
	ITEM_COL,
	QTY_COL,
	PRICE_COL,
	NUM_COLS
};
#endif

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

#if 0
static const GtkTargetEntry drag_targets = { 
	"STRING", GTK_TARGET_SAME_APP,TARGET_STRING
};

static guint n_targets = 1;

/* Could be used instead, if GtkTargetEntry had more than one row */
//static guint n_targets = G_N_ELEMENTS (drag_targets);
#endif

/* Convenience function to print out the contents of a DATA struct onto stdout */
void print_DATA(array data){
	write("DATA @ %x\n", hash_value(data));
	write(" |->row = %s\n",data[0]);
	write(" |->item = %s\n",data[1]);
	write(" |->qty = %d\n",data[2]);
	write(" +->price = %f\n",data[3]);
}

/* User callback for "get"ing the data out of the row that was DnD'd */
#if 0
void on_drag_data_get(	GtkWidget *widget, GdkDragContext *drag_context,
			GtkSelectionData *sdata, guint info, guint time,
			gpointer user_data){
	GtkTreeIter iter;
	GtkTreeModel *list_store;
	GtkTreeSelection *selector;
	gboolean rv;
	printf("on_drag_data_get: ");

	/* Get the selector widget from the treeview in question */
	selector = gtk_tree_view_get_selection(GTK_TREE_VIEW(widget));

	/* Get the tree model (list_store) and initialise the iterator */
	rv = gtk_tree_selection_get_selected(selector,&list_store,&iter);

	/* This shouldn't really happen, but just in case */
	if(rv==FALSE){
		printf(" No row selected\n");
		return;
	}

	/* Always initialise a GValue with 0 */
	GValue value={0,};
	char *cptr;

	/* Allocate a new row to send off to the other side */
	struct DATA *temp = malloc(sizeof(struct DATA));

	/* Go through the columns */
	
	/* Get the GValue of a particular column from the row, the iterator currently points to*/
	gtk_tree_model_get_value(list_store,&iter,ROW_COL,&value);
	cptr = (char*) g_value_get_string(&value);
	temp->row = malloc(strlen(cptr)*sizeof(char)+1);
	strcpy(temp->row,cptr);
	g_value_unset(&value);
	
	gtk_tree_model_get_value(list_store,&iter,ITEM_COL,&value);
	cptr = (char*)g_value_get_string(&value);
	temp->item = malloc(strlen(cptr)*sizeof(char)+1);
	strcpy(temp->item,cptr);
	g_value_unset(&value);

	gtk_tree_model_get_value(list_store,&iter,QTY_COL,&value);
	temp->qty = g_value_get_int(&value);
	g_value_unset(&value);
	
	gtk_tree_model_get_value(list_store,&iter,PRICE_COL,&value);
	temp->price = g_value_get_float(&value);
	g_value_unset(&value);
	
	/* Send the data off into the GtkSelectionData object */
	gtk_selection_data_set(sdata,
		gdk_atom_intern ("struct DATA pointer", FALSE),
		8,		/* Tell GTK how to pack the data (bytes) */
		(void *)&temp,  /* The actual pointer that we just made */
		sizeof (temp)); /* The size of the pointer */
			
	/* Just print out what we sent for debugging purposes */
	print_DATA(temp);
}

/* User callback for putting the data into the other treeview */
void on_drag_data_received(GtkWidget *widget, GdkDragContext *drag_context,
			gint x, gint y, GtkSelectionData *sdata, guint info,
			guint time, gpointer user_data){

	GtkTreeModel *list_store;	
	GtkTreeIter iter;

	printf("on_drag_data_received:\n");

	/* Remove row from the source treeview */
	GtkTreeSelection *selector;
	selector = gtk_tree_view_get_selection(GTK_TREE_VIEW(user_data));
	gtk_tree_selection_get_selected(selector,&list_store,&iter);
	gtk_list_store_remove(GTK_LIST_STORE(list_store),&iter);

	/* Now add to the other treeview */
	GtkTreeModel *list_store2;
	GtkTreeIter iter2;
	list_store2 = gtk_tree_view_get_model(GTK_TREE_VIEW(widget));
	gtk_list_store_append(GTK_LIST_STORE(list_store2),&iter2);

	/* Copy the pointer we received into a new struct */
	struct DATA *temp = NULL;
	const guchar *my_data = gtk_selection_data_get_data (sdata);
	memcpy (&temp, my_data, sizeof (temp));

	/* Add the received data to the treeview model */
	gtk_list_store_set(GTK_LIST_STORE(list_store2),&iter2,
		ROW_COL,temp->row,
		ITEM_COL,temp->item,
		QTY_COL,temp->qty,
		PRICE_COL,temp->price,-1);

	/* We dont need this anymore */
	free_DATA(temp);
}
#endif

/* User callback just to see which row was selected, doesnt affect DnD. 
   However it might be important to note that this signal and drag-data-received may occur at the same time. If you drag a row out of one view, your selection changes too */
#if 0
void on_selection_changed (GtkTreeSelection *treeselection,gpointer user_data){
	GtkTreeIter iter;
	GtkTreeModel *list_store;
	gboolean rv;
	printf("on_selection_changed: ");

	rv = gtk_tree_selection_get_selected(treeselection,
		&list_store,&iter);
	/* "changed" signal sometimes fires blanks, so make sure we actually 
	 have a selection/
http://library.gnome.org/devel/gtk/stable/GtkTreeSelection.html#GtkTreeSelection-changed */
	if (rv==FALSE){
		printf("No row selected\n");
		return;
	}
	
	GValue value={0,};
	char *cptr;
	int i;

	/* Walk throw the columns to see the row data */
	for(i=0;i<NUM_COLS;i++){
		gtk_tree_model_get_value(list_store,&iter,i,&value);
		cptr = (gchar *) g_strdup_value_contents (&value);
		g_value_unset(&value);
		if(cptr)printf("%s|",cptr);
		free(cptr);
	}
	printf("\n");

}
#endif

/* Creates a scroll windows,  puts a treeview in it and populates it */
GTK2.Widget add_treeview(GTK2.Box box, array data){
	GTK2.Widget swindow = GTK2.ScrolledWindow()->set_policy(GTK2.POLICY_AUTOMATIC, GTK2.POLICY_AUTOMATIC);
	/* Add this window to the box */
	box->pack_start(swindow, 1, 1, 2);

	/* Create the treeview and its list store */
	GTK2.ListStore list_store = GTK2.ListStore(
		({"string", "string", "int", "float"}));

	GTK2.Widget tree_view = GTK2.TreeView(list_store);

	/* Add the treeview to the scrolled window */
	swindow->add(tree_view);
		
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
	#if 0
	g_signal_connect(
		gtk_tree_view_get_selection (GTK_TREE_VIEW(tree_view)),
		"changed",G_CALLBACK(on_selection_changed),NULL);
	#endif
	return tree_view;
}

int main(int argc, array(string) argv){
	GTK2.setup_gtk(argv);

	/* Create the top level window and setup the quit callback */
	GTK2.Hbox hbox;
	GTK2.Window window = GTK2.Window(GTK.WINDOW_TOPLEVEL)
		->add(GTK2.Vbox(0, 10)
			->pack_start(GTK2.Label(DESCRIPTION), 0, 0, 1)
			->pack_start(hbox = GTK2.Hbox(1, 1), 1, 1, 1)
		)
		->set_default_size(666,266);
	window->signal_connect("destroy", lambda() {exit(0);});

	/* Create treeview 1 */
	GTK2.Widget view1 = add_treeview(hbox,row_data);

	#if 0
	/* Set treeview 1 as the source of the Drag-N-Drop operation */
	gtk_drag_source_set(view1,GDK_BUTTON1_MASK, &drag_targets,n_targets,
		GDK_ACTION_COPY|GDK_ACTION_MOVE);
	/* Attach a "drag-data-get" signal to send out the dragged data */
	g_signal_connect(view1,"drag-data-get",
		G_CALLBACK(on_drag_data_get),NULL);
	#endif

	/* Create treeview 2 */
	GTK2.Widget view2 = add_treeview(hbox,row2_data);

	#if 0
	/* Set treeview 2 as the destination of the Drag-N-Drop operation */
	gtk_drag_dest_set(view2,GTK_DEST_DEFAULT_ALL,&drag_targets,n_targets,
		GDK_ACTION_COPY|GDK_ACTION_MOVE); 
	/* Attach a "drag-data-received" signal to pull in the dragged data */
	g_signal_connect(view2,"drag-data-received",
		G_CALLBACK(on_drag_data_received),view1);
	#endif

	/* Rock'n Roll */
	window->show_all();
	return -1;
}