class SchedulesController < ApplicationController
	def show
		@schedule = Schedule.find_by_id(params[:id])
	end

	def action(action)
		@schedule = Schedule.find_by_id(params[:id])
		
		puts "action requested: #{params[:action]}"

		section = Section.find_by_crn(params[:crn])
		if action == :delete
			@schedule.sections.delete(section)
		elsif action == :add
			@schedule.sections << section
		end
		@schedule.save

		head :ok
	end

	def add
		action :add
	end

	def delete
		action :delete
	end
end