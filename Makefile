.PHONY: project clean

project:
	xcodegen generate

clean:
	rm -rf WMInspections.xcodeproj
