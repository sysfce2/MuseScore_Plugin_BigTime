//  musescore-bigtime-plugin
//  Copyright (C) 2022  RunasSudo (Lee Yingtong Li)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import QtQuick 2.0
import MuseScore 3.0

MuseScore {
	version: "1.0"
	description: "BigTime"
	menuPath: "Plugins.BigTime"
	
	onRun: {
		if (!curScore) {
			Qt.quit();
		}
		
		var cursor = curScore.newCursor(); // TODO: Is this necessary?
		
		// Delete all large time signatures so they can be rebuilt
		var segment = curScore.firstSegment();
		while (segment !== null) {
			for (var i = 0; i < segment.annotations.length; i++) {
				var annotation = segment.annotations[i];
				if (annotation.name === "StaffText" && annotation.subStyle === Tid.USER1) {
					removeElement(annotation);
				}
			}
			segment = segment.next;
		}
		
		// Hide and reserve space from native time signatures
		// Do this first to allow page layout to reflow
		var segment = curScore.firstSegment();
		while (segment !== null) {
			if (segment.segmentType == 0x10) { // SegmentType.TimeSig
				for (var track = 0; track < curScore.ntracks; track++) {
					var element = segment.elementAt(track);
					if (element && element.name === "TimeSig") {
						console.log("tick:", segment.tick, "track:", track, "ts:", element.timesig.str);
						
						element.color.a = 0; // Sets alpha to 0
						element.scale.width = 2;
					}
				}
			}
			segment = segment.next;
		}
		
		// Add large time signatures
		var segment = curScore.firstSegment();
		while (segment !== null) {
			if (segment.segmentType == 0x10) { // SegmentType.TimeSig
				for (var track = 0; track < curScore.ntracks; track++) {
					var element = segment.elementAt(track);
					if (element && element.name === "TimeSig") {
						if (track === 0) {
							var txtTimeSig = newElement(Element.STAFF_TEXT);
							txtTimeSig.autoplace = false;
							txtTimeSig.subStyle = Tid.USER1;
							txtTimeSig.fontSize = 113; // Too large to set in GUI
							txtTimeSig.text = element.timesig.numerator + "\n" + element.timesig.denominator;
							
							//segment.annotations.push(txtTimeSig); // This doesn't work I guess
							cursor.track = 0;
							cursor.rewindToTick(segment.tick);
							cursor.add(txtTimeSig);
							
							// Calculate required offset
							var offset = element.pagePos.x + element.bbox.width/2 - txtTimeSig.pagePos.x;
							txtTimeSig.offsetX += offset;
						}
					}
				}
			}
			segment = segment.next;
		}
		
		Qt.quit();
	}
}
