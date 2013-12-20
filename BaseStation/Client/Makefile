HEADER_H=../../TmoteComm.h
BUILD_EXTRA_DEPS += DataSaver.class

DataSaver.class: $(wildcard *.java) SensorsMsg.java RadioMsg.java
	javac *.java

SensorsMsg.java: $(HEADER_H)
	mig -target=null -java-classname=SensorsMsg java $(HEADER_H) sensors_msg -o $@

RadioMsg.java: $(HEADER_H)
	mig -target=null -java-classname=RadioMsg java $(HEADER_H) radio_msg -o $@

clean:
	rm -f *.class $(GEN)

