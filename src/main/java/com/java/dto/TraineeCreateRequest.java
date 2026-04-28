package com.java.dto;

import com.java.game.entity.Gender;
import com.java.game.entity.Grade;
import java.time.LocalDate;

public class TraineeCreateRequest {

	private String name;
	private Gender gender;
	private Grade grade;
	private Integer age;
	private LocalDate birthday;
	private Integer height;
	private String hobby;
	private String instagram;
	private Integer vocal;
	private Integer dance;
	private Integer star;
	private Integer mental;
	private Integer teamwork;
	private String imagePath;
	private String unlockCondition;
	private Integer unlockScore;

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Gender getGender() {
		return gender;
	}

	public void setGender(Gender gender) {
		this.gender = gender;
	}

	public Integer getVocal() {
		return vocal;
	}

	public Grade getGrade() {
		return grade;
	}

	public void setGrade(Grade grade) {
		this.grade = grade;
	}

	public Integer getAge() {
		return age;
	}

	public void setAge(Integer age) {
		this.age = age;
	}

	public LocalDate getBirthday() {
		return birthday;
	}

	public void setBirthday(LocalDate birthday) {
		this.birthday = birthday;
	}

	public Integer getHeight() {
		return height;
	}

	public void setHeight(Integer height) {
		this.height = height;
	}

	public String getHobby() {
		return hobby;
	}

	public void setHobby(String hobby) {
		this.hobby = hobby;
	}

	public String getInstagram() {
		return instagram;
	}

	public void setInstagram(String instagram) {
		this.instagram = instagram;
	}

	public void setVocal(Integer vocal) {
		this.vocal = vocal;
	}

	public Integer getDance() {
		return dance;
	}

	public void setDance(Integer dance) {
		this.dance = dance;
	}

	public Integer getStar() {
		return star;
	}

	public void setStar(Integer star) {
		this.star = star;
	}

	public Integer getMental() {
		return mental;
	}

	public void setMental(Integer mental) {
		this.mental = mental;
	}

	public Integer getTeamwork() {
		return teamwork;
	}

	public void setTeamwork(Integer teamwork) {
		this.teamwork = teamwork;
	}

	public String getImagePath() {
		return imagePath;
	}

	public void setImagePath(String imagePath) {
		this.imagePath = imagePath;
	}

	public String getUnlockCondition() {
		return unlockCondition;
	}

	public void setUnlockCondition(String unlockCondition) {
		this.unlockCondition = unlockCondition;
	}

	public Integer getUnlockScore() {
		return unlockScore;
	}

	public void setUnlockScore(Integer unlockScore) {
		this.unlockScore = unlockScore;
	}
}
