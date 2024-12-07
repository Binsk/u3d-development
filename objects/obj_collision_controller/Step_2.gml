if (current_time - update_last < update_delay)
	return;

update_last = current_time;
signaler.signal("process_pre");
process();
signaler.signal("process_post");