if (current_time - update_last < update_delay)
	return;

update_last = current_time;
process();