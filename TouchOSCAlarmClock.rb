#Sonic Pi playing and speaking clock by Robin Newman Sep 2021
#extended from a project in Feb 2018 to include visual output using new TouchOSC
#also addeed is 24 hour alarm clock functionailly
#requires samples saying zero,1-20,30,40 and 50 saved in that order in a folder.
#uses Ruby Time.now function to get time info. This is split up by functions
#hours, mins and secs to give three integer values (24 hour clock)

use_sched_ahead_time 0.1#use_real_time  #important no delays for a clock!
use_debug false

use_osc "#{get(:ip)}",9000 #localtion and input port for TouchOSC

define :parse_sync_address do |address| #enables wild card address matching to be decoded
  v = get_event(address).to_s.split(",")[6]
  if v !=nil
    return v[3..-2].split("/")
  else
    return["error"]
  end
end

define :setup do #setup display intialisation
  osc "/alarmHr/1",1
  osc "/alarmMin/1",1
  osc "/extraMin/1",1
  osc "/alarmSet",0
  sleep 0.1
  5.times do |i| #extrea mins 0-4 scale
    osc "/exMin/"+(i+1).to_s,(i).to_s
  end
  12.times do |i| #hours and min scales
    osc "/AlHr/"+(i+1).to_s,(i).to_s
    osc "/AlMin/"+(i+1).to_s,(i*5).to_s
  end
  osc "/setPM",0 #PM initial state (AM)
  set :pm,false
  set :alarmHour,0
  set :alarmMinute,0
  set :alarmExtraMinute,0
  set :alarmEnabled,false
end
setup

define :alarmRing do #larm ring function
  10.times do
    osc "/alarmActive","ALARM!!",1 #flash label on and off
    sample :ambi_soft_buzz,amp: 2 #sound
    sleep 0.5
    osc "/alarmActive","ALARM!!",0
    sleep 0.5
  end
end
live_loop :getPM do #get am/pm state
  use_real_time
  v = sync "/osc*/setPM"
  set :pm,v[0]>0
  if v[0]>0 #adjust hour scale accordingly
    12.times do |i|
      osc "/AlHr/"+(i+1).to_s,(i+12).to_s #am values
    end
  else
    12.times do |i|
      osc "/AlHr/"+(i+1).to_s,(i).to_s #pm values
    end
  end
  ah=get(:alarmHour)
  set :alarmHour,ah-12 if ah>11 and v[0]==0.0 #midify alarm hour setting
  set :alarmHour,ah+12 if ah<12 and v[0]>0
end

live_loop :getAlarmHour do #get alarm hour input
  v = sync "/osc*/alarmHr/*"
  if v[0]>0
    r= parse_sync_address("/osc*/alarmHr/*")
    ah= r[2].to_i - 1
    puts"pm",get(:pm),ah
    ah=ah+12 if get(:pm)
    set :alarmHour,ah.to_i
  end
end
live_loop :getAlarmMin do #€get alarm minute input
  v = sync "/osc*/alarmMin/*"
  if v[0]>0
    r= parse_sync_address("/osc*/alarmMin/*")
    puts "alarm minute #{5*(r[2].to_i-1)}"
    puts 5*(r[2].to_i-1)
    set :alarmMinute,5*(r[2].to_i-1)
  end
end

live_loop :getAlarmExMin do #get extra alarm mins input 0-4
  v = sync "/osc*/extraMin/*"
  if v[0]>0
    r= parse_sync_address("/osc*/extraMin/*")
    puts "alarm extra minute #{(r[2].to_i-1)}"
    set :alarmExtraMinute,(r[2].to_i-1)
  end
end

live_loop :enableAlarm do #get akalarmarm enable input
  v = sync "/osc*/alarmSet"
  if v[0] == 1.0
    set :alarmEnabled,true
    puts "Alarm is set at #{get(:alarmHour)} : #{get(:alarmMinute)+get(:alarmExtraMinute)}"
  else
    set :alarmEnabled,false
    puts "Alarm is switched off"
  end
end
 
r="ff0000ff";g="00ff00ff";b="0000ffff";y="ffff00ff" #colours for chimes (rgba)

define :lightChime do |n,d| #light chime light
  in_thread do
    case n
    when :c3
      c = r;num=1
    when :f3
      c=g;num=2
    when :g3
      c=b;num=3
    else
      c=y;num=4
    end
    osc "/chime/"+num.to_s,1,c
    sleep d
    osc "/chime/"+num.to_s,0,0
  end
end

define :lightBong do |k| #light bong light
  in_thread do
    osc "/bong/",1,"ffffffff"
    sleep k
    osc "/bong/",0,0
  end
end

live_loop :see,sync: :go do #send data to TouchOSC clock hands
  time = Time.new
  puts Time.now.hour,Time.now.min,Time.now.sec
  osc "/sec",1,Time.now.sec/60.0
  osc "/min",1,Time.now.min/60.0+Time.now.sec/3600.0
  osc "/hour",1,Time.now.hour%12/12.0+Time.now.min.to_f/(60*12)
  osc "/curTime","Time is #{Time.now.hour} : #{Time.now.min} : #{Time.now.sec}"
  sleep 1
end

#adjust next four lines to select options
set :enabletenths,false
set :enablesecs,false
set :enablespeech,false
set :enablechimes,false
set :inhibit,false #inhibits on the hour when hour "bongs" are played

osc "/tenths",0
osc"/secs",0
osc"/speech",0
osc"/chimes",0
#loops to todetext enable switches
live_loop :speechFlag do
  use_real_time
  fs = sync "/osc*/speech"
  puts fs[0]==1.0
  set :enablespeech,(fs[0]==1.0)
end

live_loop :tenthsFlag do
  fs = sync "/osc*/tenths"
  puts fs[0]==1.0
  set :enabletenths,(fs[0]==1.0)
end

live_loop :secsFlag do
  fs = sync "/osc*/secs"
  puts fs[0]==1.0
  set :enablesecs,(fs[0]==1.0)
end

live_loop :chimesFlag do
  fs = sync "/osc*/chimes"
  puts fs[0]==1.0
  set :enablechimes,(fs[0]==1.0)
end


path ="~/Desktop/count2" #path to samples
load_samples path
load_sample :ambi_glass_rub

use_synth :saw #synth to play notes
#first section defines data for quarter,half,three quarters and hour chimes
quarter= [:a3,:g3,:f3,:c3]
k=0.629 #interchime gap (from Westminster Clock)
qd=[k]*4 #durations for quarter chimes
rv=[0.822] #gap between groups of four chimes
half=[:f3,:a3,:g3,:c3,  :r,  :c3,:g3,:a3,:f3]
hd=[k]*4+ rv +[k]*4 #durations for half chimes
hrv=5 #gap between hour chimes and first "bong" for the hour
threequarters=[:a3,:f3,:g3,:c3,  :r,  :c3,:g3,:a3,:f3,  :r,  :a3,:g3,:f3,:c3]
tqd=[k]*4+rv+[k]*4+rv+[k]*4 #durations for threequarter chimes
hour=[:f3,:a3,:g3,:c3,  :r,  :f3,:g3,:a3,:f3,  :r,  :a3,:f3,:g3,:c3,  :r,  :c3,:g3,:a3,:f3]
hd=[k]*4+rv+[k]*4+rv+[k]*4+rv+[k]*4 #durations for hour chimes
anticipate=16*k+3*rv[0]+hrv #start hour chimes this time BEFORE the hour
anticipateInt=anticipate.to_int #int part of anticipate
anticipateFrac=anticipate-anticipateInt #fractional part of anticipate
#puts anticipateInt, anticipateFrac
bong=:c3 #pitch for "bongs"  also an octave higher

define :playsamp do |n,k| #function to play sample for chimes and "bong"
  sample :ambi_glass_rub,start: 0.09,sustain: 0.1*k,release: 0.9*k,amp: 0.6,rpitch: note(n)-note(:fs4)
end

define :playchimes do |notes,durations| #function to play series of notes with sample
  if get(:enablechimes)
    notes.zip(durations).each do |n,d|
      playsamp n,d if n !=:r
      lightChime n,d if n !=:r
      sleep d
    end
  end
end


define :playbongs do |n|
  #function to play bongs with gverb
  n=12 if n==0 #play 12 "bongs" at midnight not zero
  n=n-12 if n>12
  n.times do
    lightBong k
    playsamp bong, k
    playsamp note(bong+12),k
    sleep 1
  end
end
#end of chimes setup

define :speak do |n,hm=0| #n is integer 0...59, v allows volums change if required
  mutesample=0
  mutesample=1 if get(:enablespeech) #don't mute whole live loop so still get printout
  f=n/10 #first digit
  s=n%10  #second digit
  if n < 21 #up to 20 recorded as a single sample
    puts "Number to speak is #{n}"
    sample path,n ,amp: mutesample
    sleep 0.75 #gap before next sample
  else #above 20 may require two samples to speak
    puts "Two samples to speak: #{f*10}, #{s}" if s>0
    puts "Number to speak is  #{f*10}" if s==0
    sample path,[20,21,22,23][f-2],amp: mutesample #f-2 gives offset to required sample
    sleep 0.75 #gap between speaking samples
    sample path,s ,amp: mutesample if s>0
    sleep 0.75 if s > 0 #extra gap if two samples used
  end
  if get(:enablespeech) #only add further speech if enabled
    sample path,24 if hm==0  #add "seconds"
    sample path,25 if hm==1 and mins != 1#add "minutes"
    sample path,25,finish: 0.58 if hm==1 and mins ==1 #cut the s at the end of minute
    sample path,26 if hm==2 #add "hours"
  end
  sleep 0.75 #allows for different sections in the loop to have completed before next pass
end

define :hours do #returns hours as an integer 0-23
  return Time.now.hour
end

define :mins do #returns minutes as an integer 0-59
  return Time.now.min
end

define :secs do #returns seconds as an integer 0-59 (I have not catered for "60" leap seconds)
  return (Time.now.sec)%60
end

#audio output from here on
live_loop :triggerAlarm,sync: :go do
use_real_time
  h=hours;m=mins;s=secs
  ah=get(:alarmHour);am =get(:alarmMinute)+get(:alarmExtraMinute)
  msg = " (disabled)"
  msg = " (enabled)" if get(:alarmEnabled)
  osc "/alarmTime","Alarm Time: #{ah} : #{am} : 0" + msg
  if (h == ah) and (m == am) and (s == 0) and get(:alarmEnabled)
alarmRing
  end

# puts h,m,s
# puts get(:alarmMinute),get(:alarmExtraMinute)
# puts ah,am
  sleep 0.5
end

live_loop :announce,sync: :go do #speaks the time every minute in full (apart from when hour is "bonged")
  if secs == 0 and !get(:inhibit)
    speak hours,2
    #sleep 0.75
    speak mins,1
  end
  sleep 0.6
end

live_loop :playtime,sync: :go do #play notes for the minutes and announce seconds every 15 seconds
  cue :chimetest
  n=scale :c3,:major,num_octaves: 5 #notes to play
  muteflag=0;muteflag1=0
  muteflag=1 if get(:enablesecs)
  muteflag1=1 if get(:enabletenths)
  if secs < 30
    offset = secs
  else
    offset = 60-secs
  end
  puts "#{secs} seconds #{get(:inhibit)}"
  play n[offset],amp: 0.03*muteflag,release: 1
  in_thread do #play tenths of seconds
    use_synth :beep
    9.times do |z|
      play n[offset]+z,amp: 0.05*muteflag1,release: 0.08
      sleep 0.1
    end
    play n[offset]+9,amp: 0.05*muteflag1,release: 0.08#no sleep last time makes thread a bit shorter
  end
  in_thread do  #announce quarter minutes
    speak 15 if (secs == 15) and !get(:inhibit)
    speak 30 if (secs == 30) and !get(:inhibit)
    speak 45 if (secs == 45) and  !get(:inhibit)
  end
  sleep 1 #loop takes 1 second to complete.
end

#section to play chimes and hour "bongs" Use separate live_loop for each to try and minimise timeouts. cue from playtime loop
with_fx :gverb,room: 15,mix: 0.8 do
  live_loop :chimesQ,sync: :go do
    sync :chimetest
    set :inhibit,true if mins==14 and secs==58 and get(:enablespeech)
    if mins==15 and secs==0 #check for 15 mins past hour
      playchimes quarter,qd #play quarter chimes
      set :inhibit,false
    end
  end
  live_loop :chimesH,sync: :go do
    sync :chimetest
    set :inhibit,true if mins==29 and secs==58 and get(:enablespeech)
    if mins==30 and secs==0 #check for 30 mins past hour
      playchimes half,hd #play half hour chimes
      set :inhibit,false
    end
  end
  live_loop :chimesT,sync: :go do
    sync :chimetest
    set :inhibit,true if mins==44 and secs==58 and get(:enablespeech)
    if mins==45 and secs==0 #check for 45 mins past hour
      playchimes threequarters,tqd #play three quarters chimes
      set :inhibit,false
    end
  end
  live_loop :chimesF,sync: :go do
    sync :chimetest
    if mins==59 and secs==60-anticipateInt
      set :inhibit,true #anticipate the hour to allow chimes to finish
      sleep anticipateFrac
      playchimes hour,hd #play chimes for the hour (in advnace of thr actual hour)
      #sleep 12 #allow time for chimes to finish
      #set :inhibit,false #leave true for subsequent hour bongs
    end
  end
  live_loop :chimesB,sync: :go do
    sync :chimetest
    if mins== 0 and secs==0 and get(:enablechimes) #play a "bong" for each hour at second intervals
      playbongs hours
      set :inhibit,false
    end
  end
end

######## following code syncs and starts the live loops
sleep 1 #wait 1 sec to allow loops and sample loads to settle
set :t,secs #store current secs in time state
until secs>get(:t)
  sleep 0.05
end
cue :go #trigger loops on a secs change
